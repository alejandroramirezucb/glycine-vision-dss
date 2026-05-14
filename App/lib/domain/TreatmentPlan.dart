import 'Treatment.dart';

class TreatmentPriority {
  final String pathogenClass;
  final String severityLevel;
  final String urgencia;
  final String rationale;
  final TreatmentActions actions;

  const TreatmentPriority({
    required this.pathogenClass,
    required this.severityLevel,
    required this.urgencia,
    required this.rationale,
    required this.actions,
  });
}

class TreatmentActions {
  final String quimico;
  final String cultural;
  final String biologico;
  final String preventivo;
  final List<Fuente> fuentes;

  const TreatmentActions({
    required this.quimico,
    required this.cultural,
    required this.biologico,
    required this.preventivo,
    required this.fuentes,
  });
}

class TreatmentPlan {
  final List<TreatmentPriority> priorities;
  final List<String> warnings;
  final String? ventanaAplicacion;
  final String? ajusteClimatico;

  const TreatmentPlan({
    required this.priorities,
    required this.warnings,
    required this.ventanaAplicacion,
    required this.ajusteClimatico,
  });

  bool get isEmpty => priorities.isEmpty;
}
