import '../domain/ClimateData.dart';
import '../domain/OnsetEstimate.dart';
import '../domain/Protocols.dart';
import '../domain/StringNormalizer.dart';

class OnsetEstimatorImpl implements OnsetEstimator {
  static const Map<String, Map<String, List<int>>> _table = {
    'roya': {
      'minima': [2, 5],
      'leve': [5, 10],
      'moderada': [10, 18],
      'severa': [18, 28],
      'critica': [28, 45],
    },
    'fungicas': {
      'minima': [3, 7],
      'leve': [7, 14],
      'moderada': [14, 21],
      'severa': [21, 35],
      'critica': [35, 55],
    },
    'bacterianas': {
      'minima': [2, 6],
      'leve': [6, 12],
      'moderada': [12, 20],
      'severa': [20, 30],
      'critica': [30, 45],
    },
    'virales': {
      'minima': [5, 10],
      'leve': [10, 18],
      'moderada': [18, 30],
      'severa': [30, 45],
      'critica': [45, 70],
    },
    'plagas_insectos': {
      'minima': [1, 3],
      'leve': [3, 7],
      'moderada': [7, 14],
      'severa': [14, 21],
      'critica': [21, 35],
    },
  };

  const OnsetEstimatorImpl();

  @override
  OnsetEstimate estimate({
    required String pathogenClass,
    required String severityLevel,
    ClimateData? climate,
  }) {
    final clase = normalizeKey(pathogenClass);
    final nivel = normalizeKey(severityLevel);
    final byClass = _table[clase];
    if (byClass == null) {
      return const OnsetEstimate(minDays: 0, maxDays: 0, explanation: 'Clase desconocida');
    }
    final base = byClass[nivel];
    if (base == null) {
      return const OnsetEstimate(minDays: 0, maxDays: 0, explanation: 'Nivel desconocido');
    }

    var minD = base[0];
    var maxD = base[1];

    if (climate == null) {
      return OnsetEstimate(minDays: minD, maxDays: maxD, explanation: '$minD-$maxD dias (sin clima)');
    }

    final (factor, note) = _climateAdjustment(clase, climate);
    final adjMin = (minD * factor).round().clamp(1, 999);
    final adjMax = (maxD * factor).round().clamp(adjMin + 1, 999);
    final explanation = note.isEmpty ? '$minD-$maxD dias' : '$note → $adjMin-$adjMax dias';

    return OnsetEstimate(minDays: adjMin, maxDays: adjMax, explanation: explanation);
  }

  (double, String) _climateAdjustment(String clase, ClimateData climate) {
    final t = climate.tempC;
    final h = climate.humidity;
    final p = climate.precipMm;

    return switch (clase) {
      'roya' when h > 80 && t >= 20 && t <= 28 => (0.7, 'clima favorable acelera onset'),
      'roya' when h < 50 => (1.3, 'humedad baja desacelera onset'),
      'fungicas' when h > 75 => (0.8, 'alta humedad acelera fungicas'),
      'bacterianas' when p > 3 => (0.8, 'lluvia favorece dispersion bacteriana'),
      'virales' when t > 28 => (0.85, 'temperatura alta favorece vectores'),
      'plagas_insectos' when t >= 24 && t <= 32 => (0.75, 'temperatura optima acelera ciclo'),
      _ => (1.0, ''),
    };
  }
}
