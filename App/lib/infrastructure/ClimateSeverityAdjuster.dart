import '../domain/ClimateData.dart';

class ClimateSeverityAdjuster {
  static const List<String> _severityOrder = ['minima', 'leve', 'moderada', 'severa', 'critica'];

  String adjust(String baseSeverity, String diseaseKey, ClimateData? climate) {
    if (climate == null) return baseSeverity;
    final shift = _climateShift(diseaseKey, climate);
    final base = _severityOrder.indexOf(baseSeverity.toLowerCase());
    final shifted = (base + shift).clamp(0, _severityOrder.length - 1);
    return _severityOrder[shifted];
  }

  int _climateShift(String key, ClimateData c) {
    final t = c.tempC;
    final h = c.humidity;
    final p = c.precipMm;
    return switch (key) {
      'roya' when h > 80 && t >= 20 && t <= 28 => 1,
      'roya' when h < 50 => -1,
      'fungicas' when h > 75 => 1,
      'bacterianas' when p > 3 => 1,
      'virales' when t > 28 => 1,
      'plagas_insectos' when t >= 24 && t <= 32 => 1,
      _ => 0,
    };
  }
}
