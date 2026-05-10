class Fuente {
  final String texto;
  final String url;

  const Fuente({required this.texto, required this.url});

  factory Fuente.fromJson(Map<String, dynamic> json) =>
      Fuente(texto: json['texto'] as String, url: json['url'] as String);
}

class TreatmentInfo {
  final String diseaseKey;
  final String nombreEs;
  final String patogenos;
  final String sintomas;
  final String quimico;
  final String cultural;
  final String biologico;
  final String preventivo;
  final String urgencia;
  final List<Fuente> fuentes;

  const TreatmentInfo({
    required this.diseaseKey,
    required this.nombreEs,
    required this.patogenos,
    required this.sintomas,
    required this.quimico,
    required this.cultural,
    required this.biologico,
    required this.preventivo,
    required this.urgencia,
    required this.fuentes,
  });

  factory TreatmentInfo.fromJson(String key, Map<String, dynamic> json) =>
      TreatmentInfo(
        diseaseKey: key,
        nombreEs: json['nombre_es'] as String,
        patogenos: json['patogenos'] as String,
        sintomas: json['sintomas'] as String,
        quimico: json['tratamiento']['quimico'] as String,
        cultural: json['tratamiento']['cultural'] as String,
        biologico: json['tratamiento']['biologico'] as String,
        preventivo: json['tratamiento']['preventivo'] as String,
        urgencia: json['urgencia'] as String,
        fuentes: (json['fuentes'] as List)
            .map((f) => Fuente.fromJson(f as Map<String, dynamic>))
            .toList(),
      );
}
