class ClimateData {
  final double tempC;
  final double humidity;
  final double precipMm;
  final double dewpointC;
  final DateTime fetchedAt;

  const ClimateData({
    required this.tempC,
    required this.humidity,
    required this.precipMm,
    required this.dewpointC,
    required this.fetchedAt,
  });

  factory ClimateData.fromJson(Map<String, dynamic> json) => ClimateData(
        tempC: (json['temp_c'] as num).toDouble(),
        humidity: (json['humidity'] as num).toDouble(),
        precipMm: (json['precip_mm'] as num).toDouble(),
        dewpointC: (json['dewpoint_c'] as num? ?? 0).toDouble(),
        fetchedAt: DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'temp_c': tempC,
        'humidity': humidity,
        'precip_mm': precipMm,
        'dewpoint_c': dewpointC,
      };
}
