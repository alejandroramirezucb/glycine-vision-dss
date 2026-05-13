import 'dart:ui';

class ZoneDetection {
  final Rect bbox;
  final String pathogenClass;
  final double pathogenConfidence;
  final Map<String, double> pathogenDistribution;
  final double severityPct;
  final String severityLevel;
  final String urgencia;

  const ZoneDetection({
    required this.bbox,
    required this.pathogenClass,
    required this.pathogenConfidence,
    required this.pathogenDistribution,
    required this.severityPct,
    required this.severityLevel,
    required this.urgencia,
  });

  factory ZoneDetection.fromJson(Map<String, dynamic> json) {
    final b = (json['bbox'] as List).map((e) => (e as num).toDouble()).toList();
    final dist = <String, double>{};
    final rawDist = json['distribucion'] as Map<String, dynamic>? ?? {};
    rawDist.forEach((k, v) => dist[k] = (v as num).toDouble());
    return ZoneDetection(
      bbox: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
      pathogenClass: json['patogeno'] as String,
      pathogenConfidence: (json['confianza'] as num).toDouble(),
      pathogenDistribution: dist,
      severityPct: (json['severidad_pct'] as num).toDouble(),
      severityLevel: json['nivel'] as String,
      urgencia: json['urgencia'] as String? ?? '',
    );
  }
}
