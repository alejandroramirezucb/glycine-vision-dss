class OnsetEstimate {
  final int minDays;
  final int maxDays;
  final String explanation;

  const OnsetEstimate({
    required this.minDays,
    required this.maxDays,
    required this.explanation,
  });

  factory OnsetEstimate.fromJson(Map<String, dynamic> json) => OnsetEstimate(
        minDays: (json['min_days'] as num).toInt(),
        maxDays: (json['max_days'] as num).toInt(),
        explanation: json['explanation'] as String? ?? '',
      );

  String get rangeLabel => '$minDays-$maxDays dias';
}
