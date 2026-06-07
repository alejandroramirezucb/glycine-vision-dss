import 'Treatment.dart';

class TreatmentPriority {
  final String pathogenClass;
  final String severityLevel;
  final String rationale;
  final TreatmentActions actions;
  final String dosageNote;

  const TreatmentPriority({
    required this.pathogenClass,
    required this.severityLevel,
    required this.rationale,
    required this.actions,
    this.dosageNote = '',
  });
}

class TreatmentPlan {
  final List<TreatmentPriority> priorities;
  final List<String> warnings;
  final String? applicationWindow;
  final String? climateGuidance;
  final double fieldAreaHa;
  final String? sprayVolume;

  const TreatmentPlan({
    required this.priorities,
    required this.warnings,
    this.applicationWindow,
    this.climateGuidance,
    this.fieldAreaHa = 1.0,
    this.sprayVolume,
  });

  bool get isEmpty => priorities.isEmpty;
}
