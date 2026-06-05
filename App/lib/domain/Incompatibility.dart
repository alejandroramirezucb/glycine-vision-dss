class Incompatibility {
  final List<String> products;
  final String reason;

  const Incompatibility({required this.products, required this.reason});

  factory Incompatibility.fromJson(Map<String, dynamic> json) => Incompatibility(
        products: (json['products'] as List).map((e) => e.toString()).toList(),
        reason: json['reason'] as String,
      );
}
