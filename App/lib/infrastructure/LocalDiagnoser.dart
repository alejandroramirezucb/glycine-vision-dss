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
  static const int _defaultStride = 75;
  static const int _defaultMaxSide = 400;
  static const double _defaultDiseaseGate = 0.5;
  static const double _defaultActiveThreshold = 0.4;
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
    final scan = _scanImage(resized);
    final findings = _aggregateFindings(scan.zones, scan.totalPatches);
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

  _ScanResult _scanImage(img.Image image) {
    final zones = <Zone>[];
    var totalPatches = 0;
    for (var y = 0; y + patchSize <= image.height; y += stride) {
      for (var x = 0; x + patchSize <= image.width; x += stride) {
        totalPatches++;
        final patch = img.copyCrop(image, x: x, y: y, width: patchSize, height: patchSize);
        final zone = _analyzePatch(patch, x, y);
        if (zone != null) zones.add(zone);
      }
    }
    return _ScanResult(zones, totalPatches);
  }

  Zone? _analyzePatch(img.Image patch, int x, int y) {
    final healthScores = _healthModel.run(patch);
    final probDiseased = _probabilityDiseased(healthScores);
    if (probDiseased < healthGate) return null;

    final severity = _severity.calculate(patch);
    if (severity.percent < 2.0) return null;

    final diseaseScores = _diseaseModel.run(patch);
    final actives = _activeDiseases(diseaseScores, severity.percent);
    if (actives.isEmpty) return null;

    return Zone(
      bbox: Rect.fromLTWH(
        x.toDouble(),
        y.toDouble(),
        patchSize.toDouble(),
        patchSize.toDouble(),
      ),
      severityPct: severity.percent,
      severityLevel: severity.level,
      activeDiseases: actives,
    );
  }

  double _probabilityDiseased(List<double> scores) {
    final labels = _healthModel.labels;
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      final l = labels[i].toLowerCase();
      if (l.contains('enferm') || l.contains('diseased')) return scores[i];
    }
    if (scores.length == 1) return scores[0];
    return scores.length > 1 ? scores[1] : 0.0;
  }

  List<ActiveDisease> _activeDiseases(List<double> scores, double totalSeverityPct) {
    final labels = _diseaseModel.labels;
    final hits = <_LabelScore>[];
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      final label = labels[i];
      final threshold = _diseaseModel.thresholdFor(label);
      final cutoff = threshold < activeThreshold ? threshold : activeThreshold;
      if (scores[i] >= cutoff) {
        hits.add(_LabelScore(label, scores[i]));
      }
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

  List<DiseaseFinding> _aggregateFindings(List<Zone> zones, int totalPatches) {
    final byClass = <String, _ClassAccumulator>{};
    for (final zone in zones) {
      for (final disease in zone.activeDiseases) {
        final acc = byClass.putIfAbsent(
          disease.pathogenClass,
          () => _ClassAccumulator(),
        );
        acc.add(disease.severityPct, disease.probability);
      }
    }
    final findings = byClass.entries.map((entry) {
      final acc = entry.value;
      final coverage = totalPatches == 0 ? 0.0 : acc.count / totalPatches * 100;
      return DiseaseFinding(
        pathogenClass: entry.key,
        coveragePct: coverage,
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

  const _ScanResult(this.zones, this.totalPatches);
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
