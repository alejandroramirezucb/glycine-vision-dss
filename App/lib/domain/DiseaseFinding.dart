class DiseaseFinding {
  final String pathogenClass;
  final double coveragePct;
  final double avgSeverityPct;
  final double maxSeverityPct;
  final String severityLevel;
  final double avgProbability;
  final int zoneCount;

  const DiseaseFinding({
    required this.pathogenClass,
    required this.coveragePct,
    required this.avgSeverityPct,
    required this.maxSeverityPct,
    required this.severityLevel,
    required this.avgProbability,
    required this.zoneCount,
  });

  factory DiseaseFinding.fromJson(Map<String, dynamic> json) => DiseaseFinding(
        pathogenClass: json['clase'] as String,
        coveragePct: (json['coverage_pct'] as num).toDouble(),
        avgSeverityPct: (json['avg_severidad_pct'] as num).toDouble(),
        maxSeverityPct: (json['max_severidad_pct'] as num).toDouble(),
        severityLevel: json['nivel'] as String,
        avgProbability: (json['avg_probability'] as num).toDouble(),
        zoneCount: (json['zone_count'] as num).toInt(),
      );
}
