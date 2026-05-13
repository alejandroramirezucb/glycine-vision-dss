import 'ZoneDetection.dart';

class ZoneAnalysis {
  final List<ZoneDetection> zones;
  final int totalPatches;
  final int patchSize;
  final double overallHealthyPct;
  final double overallDiseasedPct;
  final String? dominantPathogen;
  final Map<String, int> pathogenDistribution;
  final double avgSeverityPct;
  final double maxSeverityPct;
  final String? worstSeverityLevel;
  final int imageWidth;
  final int imageHeight;

  const ZoneAnalysis({
    required this.zones,
    required this.totalPatches,
    this.patchSize = 150,
    required this.overallHealthyPct,
    required this.overallDiseasedPct,
    required this.dominantPathogen,
    required this.pathogenDistribution,
    required this.avgSeverityPct,
    required this.maxSeverityPct,
    required this.worstSeverityLevel,
    required this.imageWidth,
    required this.imageHeight,
  });

  bool get isHealthy => zones.isEmpty;

  factory ZoneAnalysis.fromJson(Map<String, dynamic> json, {required int width, required int height}) {
    final overall = json['overall'] as Map<String, dynamic>;
    final zonesRaw = (json['zonas'] as List? ?? []).cast<Map<String, dynamic>>();
    final dist = <String, int>{};
    final rawDist = overall['distribucion_clases'] as Map<String, dynamic>? ?? {};
    rawDist.forEach((k, v) => dist[k] = (v as num).toInt());

    return ZoneAnalysis(
      zones: zonesRaw.map(ZoneDetection.fromJson).toList(),
      totalPatches: (overall['total_patches'] as num?)?.toInt() ?? 0,
      patchSize: (overall['patch_size'] as num?)?.toInt() ?? 150,
      overallHealthyPct: (overall['porcentaje_sano'] as num?)?.toDouble() ?? 100.0,
      overallDiseasedPct: (overall['porcentaje_enfermo'] as num?)?.toDouble() ?? 0.0,
      dominantPathogen: overall['clase_dominante'] as String?,
      pathogenDistribution: dist,
      avgSeverityPct: (overall['severidad_promedio'] as num?)?.toDouble() ?? 0.0,
      maxSeverityPct: (overall['severidad_maxima'] as num?)?.toDouble() ?? 0.0,
      worstSeverityLevel: overall['nivel_global'] as String?,
      imageWidth: width,
      imageHeight: height,
    );
  }
}
