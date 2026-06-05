class Reference {
  final String text;
  final String url;

  const Reference({required this.text, required this.url});

  factory Reference.fromJson(Map<String, dynamic> json) =>
      Reference(text: json['text'] as String, url: json['url'] as String);
}

class TreatmentActions {
  final String chemical;
  final String cultural;
  final String biological;
  final String preventive;
  final List<Reference> references;

  const TreatmentActions({
    required this.chemical,
    required this.cultural,
    required this.biological,
    required this.preventive,
    required this.references,
  });
}
