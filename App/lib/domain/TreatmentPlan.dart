import 'Treatment.dart';

class TreatmentPriority {
  final String pathogenClass;
  final String severityLevel;
  final String rationale;
  final TreatmentActions actions;

  const TreatmentPriority({
    required this.pathogenClass,
    required this.severityLevel,
    required this.rationale,
    required this.actions,
  });
}

class TreatmentPlan {
  final List<TreatmentPriority> priorities;
  final List<String> warnings;
  final String? applicationWindow;
  final String? climateGuidance;

  const TreatmentPlan({
    required this.priorities,
    required this.warnings,
    this.applicationWindow,
    this.climateGuidance,
  });

  bool get isEmpty => priorities.isEmpty;
}
