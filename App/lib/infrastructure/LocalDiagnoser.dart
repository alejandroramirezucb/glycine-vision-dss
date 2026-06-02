import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../domain/ClimateData.dart';
import '../domain/DiagnoseResult.dart';
import '../domain/Diagnoser.dart';
import '../domain/DiseaseFinding.dart';
import '../domain/OnsetEstimate.dart';
import '../domain/Protocols.dart';
import '../domain/Zone.dart';
import 'Classifier.dart';
import 'SeverityCalculator.dart';
import 'TfliteSegmenter.dart';

class LocalDiagnoser implements Diagnoser {
  static const int _defaultMaxSide = 400;
  static const double _defaultDiseaseGate = 0.10;
  static const double _defaultActiveThreshold = 0.10;
  static const List<String> _severityOrder = [
    'minima',
    'leve',
    'moderada',
    'severa',
    'critica',
  ];

  final TfliteClassifier _healthModel;
  final TfliteClassifier _diseaseModel;
  final TfliteSegmenter? _segmenter;
  final SeverityCalculator _severity;
  final TreatmentRepository _treatments;
  final ClimateRepository _climateRepo;
  final OnsetEstimator _onsetEstimator;
  final int maxImageSide;
  final double healthGate;
  final double activeThreshold;

  LocalDiagnoser({
    required TfliteClassifier healthModel,
    required TfliteClassifier diseaseModel,
    required TreatmentRepository treatments,
    required ClimateRepository climateRepo,
    required OnsetEstimator onsetEstimator,
    TfliteSegmenter? segmenter,
    SeverityCalculator severity = const SeverityCalculator(),
    this.maxImageSide = _defaultMaxSide,
    this.healthGate = _defaultDiseaseGate,
    this.activeThreshold = _defaultActiveThreshold,
  })  : _healthModel = healthModel,
        _diseaseModel = diseaseModel,
        _segmenter = segmenter,
        _severity = severity,
        _treatments = treatments,
        _climateRepo = climateRepo,
        _onsetEstimator = onsetEstimator;

  @override
  Future<DiagnoseResult> diagnose(XFile image, {double? lat, double? lon}) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Imagen inválida');

    final resized = _resizeIfNeeded(decoded);

    Uint8List? segMask;
    double globalSeverityPct = 0.0;
    double chlorosisPct = 0.0;
    double necrosisPct = 0.0;

    final seg = _segmenter;
    if (seg != null) {
      segMask = seg.segment(resized);
      globalSeverityPct = seg.severityPct(segMask);
      final decomp = seg.decompose(resized, segMask);
      chlorosisPct = decomp.chlorosis;
      necrosisPct = decomp.necrosis;
    }

    final scan = await _scanWholeImage(resized);

    final effectiveZones = scan.zones;

    final findings = _aggregateFindings(effectiveZones, scan.totalPatches, scan.leafPatches);
    final climate = await _fetchClimate(lat, lon);
    final onset = _estimateOnset(findings, climate);
    final plan = _treatments.buildComposite(findings: findings, climate: climate);

    return DiagnoseResult(
      zones: effectiveZones,
      findings: findings,
      imageWidth: resized.width,
      imageHeight: resized.height,
      patchSize: resized.width,
      totalPatches: scan.totalPatches,
      leafPatches: scan.leafPatches,
      climate: climate,
      onset: onset,
      treatmentPlan: plan,
      segMask256: segMask,
      globalSeverityPct: globalSeverityPct,
      chlorosisPct: chlorosisPct,
      necrosisPct: necrosisPct,
    );
  }

  img.Image _resizeIfNeeded(img.Image image) {
    final longest = image.width > image.height ? image.width : image.height;
    if (longest <= maxImageSide) return image;
    final scale = maxImageSide / longest;
    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );
  }

  Future<_ScanResult> _scanWholeImage(img.Image image) async {
    final b = image.getBytes(order: img.ChannelOrder.rgb);
    final mid = b.length ~/ 2;
    debugPrint('[M1-DEBUG] image=${image.width}x${image.height} bytes=${b.length} '
        'px0=[${b[0]},${b[1]},${b[2]}] px_mid=[${b[mid]},${b[mid+1]},${b[mid+2]}]');

    final healthScore = _healthModel.run(image);
    final pDiseased = _probabilityDiseased(healthScore);

    debugPrint('[M1-DEBUG] healthScore=$healthScore pDiseased=$pDiseased healthGate=$healthGate');

    if (pDiseased < healthGate) {
      return _ScanResult(const [], 1, 1);
    }

    await Future.delayed(Duration.zero);

    final diseaseScore = _diseaseModel.run(image);
    final severity = _severity.calculate(image);
    final actives = _activeDiseases(diseaseScore, severity.percent);

    if (actives.isEmpty) return _ScanResult(const [], 1, 1);

    final zone = Zone(
      bbox: Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      severityPct: severity.percent,
      severityLevel: severity.level,
      activeDiseases: actives,
    );
    return _ScanResult([zone], 1, 1);
  }

  double _probabilityDiseased(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    final labels = _healthModel.labels;
    if (labels.length <= 2) return scores[0];
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      final l = labels[i].toLowerCase();
      if (l.contains('enferm') || l.contains('soya_enferma')) return scores[i];
    }
    return scores[0];
  }

  List<ActiveDisease> _activeDiseases(List<double> scores, double totalSeverityPct) {
    final labels = _diseaseModel.labels;
    final hits = <_LabelScore>[];
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      final label = labels[i];
      final threshold = _diseaseModel.thresholdFor(label);
      final cutoff = threshold < activeThreshold ? threshold : activeThreshold;
      if (scores[i] >= cutoff) hits.add(_LabelScore(label, scores[i]));
    }
    if (hits.isEmpty) return const [];
    final sum = hits.fold<double>(0, (s, h) => s + h.score);
    return hits
        .map((h) => ActiveDisease(
              pathogenClass: h.label,
              probability: h.score,
              severityPct: sum == 0 ? 0 : totalSeverityPct * h.score / sum,
            ))
        .toList();
  }

  List<DiseaseFinding> _aggregateFindings(
      List<Zone> zones, int totalPatches, int leafPatches) {
    final byClass = <String, _ClassAccumulator>{};
    for (final zone in zones) {
      for (final disease in zone.activeDiseases) {
        byClass
            .putIfAbsent(disease.pathogenClass, _ClassAccumulator.new)
            .add(disease.severityPct, disease.probability);
      }
    }
    final denom =
        leafPatches > 0 ? leafPatches : (totalPatches > 0 ? totalPatches : 1);
    final findings = byClass.entries.map((entry) {
      final acc = entry.value;
      return DiseaseFinding(
        pathogenClass: entry.key,
        coveragePct: acc.count / denom * 100,
        avgSeverityPct: acc.avgSeverity,
        maxSeverityPct: acc.maxSeverity,
        severityLevel: _severityLevelFromPct(acc.avgSeverity),
        avgProbability: acc.avgProbability,
        zoneCount: acc.count,
      );
    }).toList();
    findings.sort((a, b) {
      final s = _rankSeverity(b.severityLevel).compareTo(_rankSeverity(a.severityLevel));
      return s != 0 ? s : b.coveragePct.compareTo(a.coveragePct);
    });
    return findings;
  }

  String _severityLevelFromPct(double pct) {
    if (pct < 5) return 'minima';
    if (pct < 15) return 'leve';
    if (pct < 35) return 'moderada';
    if (pct < 60) return 'severa';
    return 'critica';
  }

  int _rankSeverity(String level) =>
      _severityOrder.indexOf(level.toLowerCase()).clamp(0, _severityOrder.length - 1);

  Future<ClimateData?> _fetchClimate(double? lat, double? lon) async {
    if (lat == null || lon == null) return null;
    try {
      return await _climateRepo.fetch(lat, lon);
    } catch (_) {
      return null;
    }
  }

  OnsetEstimate? _estimateOnset(List<DiseaseFinding> findings, ClimateData? climate) {
    if (findings.isEmpty) return null;
    final worst = findings.first;
    return _onsetEstimator.estimate(
      pathogenClass: worst.pathogenClass,
      severityLevel: worst.severityLevel,
      climate: climate,
    );
  }
}

class _ScanResult {
  final List<Zone> zones;
  final int totalPatches;
  final int leafPatches;
  const _ScanResult(this.zones, this.totalPatches, this.leafPatches);
}

class _LabelScore {
  final String label;
  final double score;
  const _LabelScore(this.label, this.score);
}

class _ClassAccumulator {
  double _severitySum = 0;
  double _maxSeverity = 0;
  double _probSum = 0;
  int count = 0;

  void add(double severity, double probability) {
    _severitySum += severity;
    _probSum += probability;
    if (severity > _maxSeverity) _maxSeverity = severity;
    count++;
  }

  double get avgSeverity => count == 0 ? 0 : _severitySum / count;
  double get maxSeverity => _maxSeverity;
  double get avgProbability => count == 0 ? 0 : _probSum / count;
}
