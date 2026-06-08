class OnsetEstimate {
  final int minDays;
  final int maxDays;
  final String explanation;
  final bool indicated;

  const OnsetEstimate({
    required this.minDays,
    required this.maxDays,
    required this.explanation,
    this.indicated = false,
  });

  factory OnsetEstimate.fromJson(Map<String, dynamic> json) => OnsetEstimate(
        minDays: (json['min_days'] as num).toInt(),
        maxDays: (json['max_days'] as num).toInt(),
        explanation: json['explanation'] as String? ?? '',
        indicated: json['indicated'] as bool? ?? false,
      );

  String get rangeLabel => '$minDays-$maxDays días';
}
