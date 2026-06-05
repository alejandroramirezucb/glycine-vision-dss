import '../domain/TreatmentDose.dart';

class DoseCalculator {
  double calculate({
    required TreatmentDose dose,
    required double fieldAreaHa,
    required String severity,
  }) {
    final basePerHa = dose.amountLHa ?? (dose.amountG100L / 1000.0 * 10.0);
    final multiplier = dose.severityMultiplier[severity] ?? 1.0;
    return basePerHa * fieldAreaHa * multiplier;
  }
}
