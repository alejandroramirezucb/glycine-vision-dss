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
import 'TfliteSegmenter.dart';

class LocalDiagnoser implements Diagnoser {
  static const int _defaultPatchSize = 150;
  static const int _defaultStride = 100;
  static const int _defaultMaxSide = 400;
  static const double _defaultDiseaseGate = 0.35;
  static const double _defaultActiveThreshold = 0.25;
  static const double _leafRatioThreshold = 0.0;
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
    TfliteSegmenter? segmenter,
    SeverityCalculator severity = const SeverityCalculator(),
    this.patchSize = _defaultPatchSize,
    this.stride = _defaultStride,
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

  Future<_ScanResult> _scanImage(
    img.Image leafDetectionImage,
    img.Image inferenceImage,
  ) async {
    final detectionBytes = leafDetectionImage.getBytes(order: img.ChannelOrder.rgb);
    final srcW = leafDetectionImage.width;
    final srcH = leafDetectionImage.height;

    final candidates = <({int x, int y})>[];
    var totalPatches = 0;

    for (var y = 0; y + patchSize <= srcH; y += stride) {
      for (var x = 0; x + patchSize <= srcW; x += stride) {
        totalPatches++;
        if (_leafRatio(detectionBytes, srcW, x, y) >= _leafRatioThreshold) {
          candidates.add((x: x, y: y));
        }
      }
    }

    final leafPatches = candidates.length;
    if (candidates.isEmpty) return _ScanResult(const [], totalPatches, 0);

    await Future.delayed(Duration.zero);

    final healthScores = _healthModel.runBatchFromSource(inferenceImage, candidates, patchSize);
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
        _diseaseModel.runBatchFromSource(inferenceImage, diseasedCandidates, patchSize);

    final zones = <Zone>[];
    for (var j = 0; j < diseasedIndexes.length; j++) {
      final pos = candidates[diseasedIndexes[j]];
      final patch =
          img.copyCrop(inferenceImage, x: pos.x, y: pos.y, width: patchSize, height: patchSize);
      final severity = _severity.calculate(patch);
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

  Future<_ScanResult> _scanWholeImage(img.Image image) async {
    final healthScore = _healthModel.run(image);
    final pDiseased = _probabilityDiseased(healthScore);

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
        final brightness = r + g + b;
        final isLeafTissue = brightness > 60 &&
            brightness < 660 &&
            !(r > 210 && g > 210 && b > 210);
        if (isGreen || isYellow || isLeafTissue) leafCount++;
        sampleCount++;
      }
    }
    return sampleCount == 0 ? 0.0 : leafCount / sampleCount;
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
