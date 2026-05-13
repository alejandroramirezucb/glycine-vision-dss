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

  factory TreatmentInfo.fromJson(String key, Map<String, dynamic> json) {
    final fuentes = ((json['fuentes'] as List?) ?? [])
        .map((f) => Fuente.fromJson(f as Map<String, dynamic>))
        .toList();

    final porSev = json['por_severidad'] as Map<String, dynamic>?;
    Map<String, dynamic> body;
    String urgencia;
    if (porSev != null) {
      body = (porSev['moderada'] ?? porSev.values.first) as Map<String, dynamic>;
      urgencia = body['urgencia'] as String? ?? 'media';
    } else {
      body = json['tratamiento'] as Map<String, dynamic>;
      urgencia = json['urgencia'] as String? ?? 'media';
    }

    return TreatmentInfo(
      diseaseKey: key,
      nombreEs: json['nombre_es'] as String,
      patogenos: json['patogenos'] as String? ?? '',
      sintomas: json['sintomas'] as String? ?? '',
      quimico: body['quimico'] as String? ?? '',
      cultural: body['cultural'] as String? ?? '',
      biologico: body['biologico'] as String? ?? '',
      preventivo: body['preventivo'] as String? ?? '',
      urgencia: urgencia,
      fuentes: fuentes,
    );
  }

  factory TreatmentInfo.fromSeverityEntry(
    String key,
    Map<String, dynamic> base,
    Map<String, dynamic> sevBody,
  ) {
    final fuentes = ((base['fuentes'] as List?) ?? [])
        .map((f) => Fuente.fromJson(f as Map<String, dynamic>))
        .toList();
    return TreatmentInfo(
      diseaseKey: key,
      nombreEs: base['nombre_es'] as String,
      patogenos: base['patogenos'] as String? ?? '',
      sintomas: base['sintomas'] as String? ?? '',
      quimico: sevBody['quimico'] as String? ?? '',
      cultural: sevBody['cultural'] as String? ?? '',
      biologico: sevBody['biologico'] as String? ?? '',
      preventivo: sevBody['preventivo'] as String? ?? '',
      urgencia: sevBody['urgencia'] as String? ?? 'media',
      fuentes: fuentes,
    );
  }
}
