import 'dart:ui';

class ActiveDisease {
  final String pathogenClass;
  final double probability;
  final double severityPct;

  const ActiveDisease({
    required this.pathogenClass,
    required this.probability,
    required this.severityPct,
  });

  factory ActiveDisease.fromJson(Map<String, dynamic> json) => ActiveDisease(
        pathogenClass: json['clase'] as String,
        probability: (json['prob'] as num).toDouble(),
        severityPct: (json['severidad_pct'] as num).toDouble(),
      );
}

class Zone {
  final Rect bbox;
  final double severityPct;
  final String severityLevel;
  final List<ActiveDisease> activeDiseases;

  const Zone({
    required this.bbox,
    required this.severityPct,
    required this.severityLevel,
    required this.activeDiseases,
  });

  String? get dominantClass {
    if (activeDiseases.isEmpty) return null;
    var best = activeDiseases.first;
    for (final d in activeDiseases) {
      if (d.probability > best.probability) best = d;
    }
    return best.pathogenClass;
  }

  factory Zone.fromJson(Map<String, dynamic> json) {
    final b = (json['bbox'] as List).map((e) => (e as num).toDouble()).toList();
    final diseases = (json['enfermedades'] as List? ?? [])
        .map((e) => ActiveDisease.fromJson(e as Map<String, dynamic>))
        .toList();
    return Zone(
      bbox: Rect.fromLTRB(b[0], b[1], b[2], b[3]),
      severityPct: (json['severidad_pct'] as num).toDouble(),
      severityLevel: json['nivel'] as String,
      activeDiseases: diseases,
    );
  }
}
