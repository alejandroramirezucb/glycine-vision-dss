import 'dart:typed_data';
import 'dart:ui';
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

class LocalDiagnoser implements Diagnoser {
  static const int _defaultPatchSize = 150;
  static const int _defaultStride = 100;
  static const int _defaultMaxSide = 400;
  static const double _defaultDiseaseGate = 0.35;
  static const double _defaultActiveThreshold = 0.4;
  static const double _leafRatioThreshold = 0.07;
  static const List<String> _severityOrder = [
    'minima',
    'leve',
    'moderada',
    'severa',
    'critica',
  ];

  final TfliteClassifier _healthModel;
  final TfliteClassifier _diseaseModel;
  final SeverityCalculator _severity;
  final TreatmentRepository _treatments;
  final ClimateRepository _climateRepo;
  final OnsetEstimator _onsetEstimator;
  final int patchSize;
  final int stride;
  final int maxImageSide;
  final double healthGate;
  final double activeThreshold;

  LocalDiagnoser({
    required TfliteClassifier healthModel,
    required TfliteClassifier diseaseModel,
    required TreatmentRepository treatments,
    required ClimateRepository climateRepo,
    required OnsetEstimator onsetEstimator,
    SeverityCalculator severity = const SeverityCalculator(),
    this.patchSize = _defaultPatchSize,
    this.stride = _defaultStride,
    this.maxImageSide = _defaultMaxSide,
    this.healthGate = _defaultDiseaseGate,
    this.activeThreshold = _defaultActiveThreshold,
  })  : _healthModel = healthModel,
        _diseaseModel = diseaseModel,
        _treatments = treatments,
        _climateRepo = climateRepo,
        _onsetEstimator = onsetEstimator,
        _severity = severity;

  @override
  Future<DiagnoseResult> diagnose(XFile image, {double? lat, double? lon}) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Imagen inválida');

    final resized = _resizeIfNeeded(decoded);
    final scan = await _scanImage(resized);
    final findings = _aggregateFindings(scan.zones, scan.totalPatches, scan.leafPatches);
    final climate = await _fetchClimate(lat, lon);
    final onset = _estimateOnset(findings, climate);
    final plan = _treatments.buildComposite(findings: findings, climate: climate);

    return DiagnoseResult(
      zones: scan.zones,
      findings: findings,
      imageWidth: resized.width,
      imageHeight: resized.height,
      patchSize: patchSize,
      totalPatches: scan.totalPatches,
      leafPatches: scan.leafPatches,
      climate: climate,
      onset: onset,
      treatmentPlan: plan,
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

  Future<_ScanResult> _scanImage(img.Image image) async {
    final srcBytes = image.getBytes(order: img.ChannelOrder.rgb);
    final srcW = image.width;
    final srcH = image.height;

    final candidates = <({int x, int y})>[];
    var totalPatches = 0;

    for (var y = 0; y + patchSize <= srcH; y += stride) {
      for (var x = 0; x + patchSize <= srcW; x += stride) {
        totalPatches++;
        if (_leafRatio(srcBytes, srcW, x, y) >= _leafRatioThreshold) {
          candidates.add((x: x, y: y));
        }
      }
    }

    final leafPatches = candidates.length;
    if (candidates.isEmpty) return _ScanResult(const [], totalPatches, 0);

    await Future.delayed(Duration.zero);

    final healthScores =
        _healthModel.runBatchFromSource(image, candidates, patchSize);
    final diseasedIndexes = [
      for (var i = 0; i < candidates.length; i++)
        if (_probabilityDiseased(healthScores[i]) >= healthGate) i,
    ];
    if (diseasedIndexes.isEmpty) {
      return _ScanResult(const [], totalPatches, leafPatches);
    }

    await Future.delayed(Duration.zero);

    final diseasedCandidates = [for (final i in diseasedIndexes) candidates[i]];
    final diseaseScores =
        _diseaseModel.runBatchFromSource(image, diseasedCandidates, patchSize);

    final zones = <Zone>[];
    for (var j = 0; j < diseasedIndexes.length; j++) {
      final pos = candidates[diseasedIndexes[j]];
      final patch =
          img.copyCrop(image, x: pos.x, y: pos.y, width: patchSize, height: patchSize);
      final severity = _severity.calculate(patch);
      if (severity.percent < 2.0) continue;
      final actives = _activeDiseases(diseaseScores[j], severity.percent);
      if (actives.isEmpty) continue;
      zones.add(Zone(
        bbox: Rect.fromLTWH(
            pos.x.toDouble(), pos.y.toDouble(), patchSize.toDouble(), patchSize.toDouble()),
        severityPct: severity.percent,
        severityLevel: severity.level,
        activeDiseases: actives,
      ));
    }
    return _ScanResult(zones, totalPatches, leafPatches);
  }

  double _leafRatio(Uint8List srcBytes, int srcW, int startX, int startY) {
    var leafCount = 0;
    var sampleCount = 0;
    final endY = (startY + patchSize).clamp(0, srcBytes.length ~/ (srcW * 3));
    final endX = (startX + patchSize).clamp(0, srcW);
    for (var y = startY; y < endY; y += 4) {
      final rowBase = y * srcW * 3;
      for (var x = startX; x < endX; x += 4) {
        final px = rowBase + x * 3;
        final r = srcBytes[px];
        final g = srcBytes[px + 1];
        final b = srcBytes[px + 2];
        final isGreen = g > 45 && g > r * 1.05 && g > b * 1.1;
        final isYellow = g > 70 && b < 80 && g > b * 2.5 && (r - g).abs() < 65;
        if (isGreen || isYellow) leafCount++;
        sampleCount++;
      }
    }
    return sampleCount == 0 ? 0.0 : leafCount / sampleCount;
  }

  double _probabilityDiseased(List<double> scores) {
    if (scores.isEmpty) return 0.0;
    if (_healthModel.labels.length == 2) return scores[0];
    final labels = _healthModel.labels;
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      final l = labels[i].toLowerCase();
      if (l.contains('enferm') || l.contains('diseased') || l.contains('sick')) {
        return scores[i];
      }
    }
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      final l = labels[i].toLowerCase();
      if (l.contains('sana') || l.contains('health') || l.contains('normal')) {
        return 1.0 - scores[i];
      }
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
