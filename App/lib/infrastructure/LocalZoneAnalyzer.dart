import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../domain/Protocols.dart';
import '../domain/ZoneAnalysis.dart';
import '../domain/ZoneDetection.dart';
import 'Classifier.dart';
import 'SeverityCalculator.dart';

class LocalZoneAnalyzer implements ZoneAnalyzer {
  final TfliteClassifier _healthModel;
  final TfliteClassifier _diseaseModel;
  final SeverityCalculator _severity;
  final int patchSize;
  final int stride;
  final double diseaseThreshold;
  final int maxImageSide;

  LocalZoneAnalyzer({
    required TfliteClassifier healthModel,
    required TfliteClassifier diseaseModel,
    SeverityCalculator severity = const SeverityCalculator(),
    this.patchSize = 150,
    this.stride = 75,
    this.diseaseThreshold = 0.5,
    this.maxImageSide = 600,
  })  : _healthModel = healthModel,
        _diseaseModel = diseaseModel,
        _severity = severity;

  @override
  Future<ZoneAnalysis> analyze(XFile imageFile, {double? lat, double? lon}) async {
    final bytes = await imageFile.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) throw Exception('Imagen invalida');

    final image = _resizeIfNeeded(decoded);
    final w = image.width;
    final h = image.height;

    final zones = <ZoneDetection>[];
    final classCount = <String, int>{};
    final severitiesPct = <double>[];
    final levels = <String>[];
    var totalPatches = 0;

    for (var y = 0; y + patchSize <= h; y += stride) {
      for (var x = 0; x + patchSize <= w; x += stride) {
        totalPatches++;
        final patch = img.copyCrop(image, x: x, y: y, width: patchSize, height: patchSize);
        final healthScores = _healthModel.classifyImage(patch);
        final probDiseased = _probDiseased(healthScores);

        if (probDiseased < diseaseThreshold) continue;

        final diseaseScores = _diseaseModel.classifyImage(patch);
        final (cls, conf, dist) = _topClass(diseaseScores, _diseaseModel.labels);
        final sev = _severity.calculate(patch);

        zones.add(ZoneDetection(
          bbox: Rect.fromLTWH(x.toDouble(), y.toDouble(), patchSize.toDouble(), patchSize.toDouble()),
          pathogenClass: cls,
          pathogenConfidence: conf,
          pathogenDistribution: dist,
          severityPct: sev.percent,
          severityLevel: sev.level,
          urgencia: sev.urgencia,
        ));
        classCount[cls] = (classCount[cls] ?? 0) + 1;
        severitiesPct.add(sev.percent);
        levels.add(sev.level);
      }
    }

    String? dominant;
    if (classCount.isNotEmpty) {
      dominant = classCount.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    }
    final avgSev = severitiesPct.isEmpty ? 0.0 : severitiesPct.reduce((a, b) => a + b) / severitiesPct.length;
    final maxSev = severitiesPct.isEmpty ? 0.0 : severitiesPct.reduce((a, b) => a > b ? a : b);
    final worst = _worstLevel(levels);
    final diseasedPct = totalPatches == 0 ? 0.0 : (zones.length / totalPatches) * 100.0;

    return ZoneAnalysis(
      zones: zones,
      totalPatches: totalPatches,
      patchSize: patchSize,
      overallHealthyPct: double.parse((100 - diseasedPct).toStringAsFixed(1)),
      overallDiseasedPct: double.parse(diseasedPct.toStringAsFixed(1)),
      dominantPathogen: dominant,
      pathogenDistribution: classCount,
      avgSeverityPct: double.parse(avgSev.toStringAsFixed(1)),
      maxSeverityPct: double.parse(maxSev.toStringAsFixed(1)),
      worstSeverityLevel: worst,
      imageWidth: w,
      imageHeight: h,
    );
  }

  img.Image _resizeIfNeeded(img.Image image) {
    final big = image.width > image.height ? image.width : image.height;
    if (big <= maxImageSide) return image;
    final scale = maxImageSide / big;
    return img.copyResize(
      image,
      width: (image.width * scale).round(),
      height: (image.height * scale).round(),
    );
  }

  double _probDiseased(List<double> scores) {
    final labels = _healthModel.labels;
    for (var i = 0; i < labels.length && i < scores.length; i++) {
      final lab = labels[i].toLowerCase();
      if (lab.contains('enferm') || lab.contains('diseased')) return scores[i];
    }
    if (scores.length == 1) return scores[0];
    return scores.length > 1 ? scores[1] : 0.0;
  }

  (String, double, Map<String, double>) _topClass(List<double> scores, List<String> labels) {
    var topIdx = 0;
    var topVal = -1.0;
    final dist = <String, double>{};
    for (var i = 0; i < scores.length && i < labels.length; i++) {
      dist[labels[i]] = scores[i];
      if (scores[i] > topVal) {
        topVal = scores[i];
        topIdx = i;
      }
    }
    return (labels[topIdx], topVal, dist);
  }

  String? _worstLevel(List<String> levels) {
    const order = ['minima', 'leve', 'moderada', 'severa', 'critica'];
    String? worst;
    var worstIdx = -1;
    for (final l in levels) {
      final idx = order.indexOf(l);
      if (idx > worstIdx) {
        worstIdx = idx;
        worst = l;
      }
    }
    return worst;
  }
}
