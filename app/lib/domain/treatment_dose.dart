class TreatmentDose {
  final double amountG100L;
  final double? amountLHa;
  final Map<String, double> severityMultiplier;
  final int intervalDays;
  final int preHarvestDays;

  const TreatmentDose({
    required this.amountG100L,
    this.amountLHa,
    required this.severityMultiplier,
    this.intervalDays = 14,
    this.preHarvestDays = 21,
  });

  factory TreatmentDose.fromJson(Map<String, dynamic> json) => TreatmentDose(
        amountG100L: (json['dose_g_per_100L'] as num?)?.toDouble() ?? 0.0,
        amountLHa: (json['dose_L_per_ha'] as num?)?.toDouble(),
        severityMultiplier: (json['severity_multiplier'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(k, (v as num).toDouble())),
        intervalDays: (json['interval_days'] as num?)?.toInt() ?? 14,
        preHarvestDays: (json['pre_harvest_days'] as num?)?.toInt() ?? 21,
      );
}
