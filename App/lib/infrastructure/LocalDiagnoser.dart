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
import 'DiseaseColorizer.dart';
import 'SeverityCalculator.dart';
import 'TfliteSegmenter.dart';

class LocalDiagnoser implements Diagnoser {
  static const int _defaultMaxSide = 400;
  static const double _defaultDiseaseGate = 0.5;
  static const double _diseaseConfidence = 0.50;

  final TfliteClassifier _healthModel;
  final TfliteClassifier _diseaseModel;
  final TfliteSegmenter? _segmenter;
  final SeverityCalculator _severity;
  final TreatmentRepository _treatments;
  final ClimateRepository _climateRepo;
  final OnsetEstimator _onsetEstimator;
  final int maxImageSide;
  final double healthGate;

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
  })  : _healthModel = healthModel,
        _diseaseModel = diseaseModel,
        _segmenter = segmenter,
        _severity = severity,
        _treatments = treatments,
        _climateRepo = climateRepo,
        _onsetEstimator = onsetEstimator;

  @override
  Future<DiagnoseResult> diagnose(XFile image, {double? lat, double? lon, double fieldAreaHa = 1.0, DateTime? onsetDate}) async {
    final bytes = await image.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Imagen inválida');

    final resized = _resizeIfNeeded(decoded);
    final seg = _segmenter;

    Uint8List? leaf256;
    img.Image? norm256;
    img.Image leafIsolated = resized;
    if (seg != null) {
      leaf256 = seg.segmentLeaf(resized);
      norm256 = seg.normalized256(resized);
      leafIsolated = seg.applyMask(resized, leaf256);
    }

    final pDiseased = _probabilityDiseased(_healthModel.runDual(resized, leafIsolated));

    final findings = <DiseaseFinding>[];
    final zones = <Zone>[];
    Uint8List? diseaseColoredMask;
    double globalSeverityPct = 0.0;

    if (seg != null && leaf256 != null && norm256 != null && pDiseased >= healthGate) {
      await Future.delayed(Duration.zero);
      final detected = _topDisease(_diseaseModel.runDual(resized, leafIsolated));
      final sev = _severity.analyze(norm256, leaf256);
      globalSeverityPct = sev.percent;

      if (detected != null) {
        final active = ActiveDisease(
          pathogenClass: detected.label,
          probability: detected.score,
          severityPct: sev.percent,
        );
        zones.add(Zone(
          bbox: Rect.fromLTWH(0, 0, resized.width.toDouble(), resized.height.toDouble()),
          severityPct: sev.percent,
          severityLevel: sev.level,
          activeDiseases: [active],
        ));
        findings.add(DiseaseFinding(
          pathogenClass: detected.label,
          coveragePct: sev.percent,
          avgSeverityPct: sev.percent,
          maxSeverityPct: sev.percent,
          severityLevel: sev.level,
          avgProbability: detected.score,
          zoneCount: 1,
        ));
        diseaseColoredMask = DiseaseColorizer.build(sev.mask3, [active]);
      } else {
        diseaseColoredMask = DiseaseColorizer.build(sev.mask3, const []);
      }
    } else if (leaf256 != null) {
      diseaseColoredMask = DiseaseColorizer.build(leaf256, const []);
    }

    final climate = await _fetchClimate(lat, lon);
    final onset = _resolveOnset(findings, climate, onsetDate);
    final plan = _treatments.buildComposite(findings: findings, climate: climate, fieldAreaHa: fieldAreaHa);

    return DiagnoseResult(
      zones: zones,
      findings: findings,
      imageWidth: resized.width,
      imageHeight: resized.height,
      patchSize: resized.width,
      totalPatches: 1,
      leafPatches: 1,
      climate: climate,
      onset: onset,
      treatmentPlan: plan,
      diseaseColoredMask: diseaseColoredMask,
      globalSeverityPct: globalSeverityPct,
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

  _LabelScore? _topDisease(List<double> scores) {
    final labels = _diseaseModel.labels;
    var bestIndex = -1;
    var bestScore = 0.0;
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      if (scores[i] > bestScore) {
        bestScore = scores[i];
        bestIndex = i;
      }
    }
    if (bestIndex < 0 || bestScore < _diseaseConfidence) return null;
    return _LabelScore(labels[bestIndex], bestScore);
  }

  Future<ClimateData?> _fetchClimate(double? lat, double? lon) async {
    if (lat == null || lon == null) return null;
    try {
      return await _climateRepo.fetch(lat, lon);
    } catch (_) {
      return null;
    }
  }

  OnsetEstimate? _resolveOnset(
      List<DiseaseFinding> findings, ClimateData? climate, DateTime? onsetDate) {
    if (findings.isEmpty) return null;
    if (onsetDate != null) {
      final days = DateTime.now().difference(onsetDate).inDays.clamp(0, 999);
      return OnsetEstimate(minDays: days, maxDays: days, explanation: '', indicated: true);
    }
    final worst = findings.first;
    return _onsetEstimator.estimate(
      pathogenClass: worst.pathogenClass,
      severityLevel: worst.severityLevel,
      climate: climate,
    );
  }
}

class _LabelScore {
  final String label;
  final double score;
  const _LabelScore(this.label, this.score);
}
