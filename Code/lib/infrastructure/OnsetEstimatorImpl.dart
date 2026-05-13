import '../domain/ClimateData.dart';
import '../domain/OnsetEstimate.dart';
import '../domain/Protocols.dart';

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
    final clase = _normalize(pathogenClass);
    final nivel = _normalize(severityLevel);
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
    final baseLabel = 'Rango base para $clase/$nivel: $minD-$maxD dias';

    if (climate == null) {
      return OnsetEstimate(minDays: minD, maxDays: maxD, explanation: '$baseLabel (sin clima)');
    }

    double factor = 1.0;
    final notes = <String>[];
    final t = climate.tempC;
    final h = climate.humidity;
    final p = climate.precipMm;

    if (clase == 'roya') {
      if (h > 80 && t >= 20 && t <= 28) {
        factor = 0.7;
        notes.add('clima favorable acelera onset');
      } else if (h < 50) {
        factor = 1.3;
        notes.add('humedad baja desacelera onset');
      }
    } else if (clase == 'fungicas') {
      if (h > 75) {
        factor = 0.8;
        notes.add('alta humedad acelera fungicas');
      }
    } else if (clase == 'bacterianas') {
      if (p > 3) {
        factor = 0.8;
        notes.add('lluvia favorece dispersion bacteriana');
      }
    } else if (clase == 'virales') {
      if (t > 28) {
        factor = 0.85;
        notes.add('temperatura alta favorece vectores');
      }
    } else if (clase == 'plagas_insectos') {
      if (t >= 24 && t <= 32) {
        factor = 0.75;
        notes.add('temperatura optima acelera ciclo de plaga');
      }
    }

    final adjMin = (minD * factor).round().clamp(1, 999);
    final adjMax = (maxD * factor).round().clamp(adjMin + 1, 999);

    var explanation = baseLabel;
    if (notes.isNotEmpty) {
      explanation += ' | ajuste clima: ${notes.join(", ")} -> $adjMin-$adjMax dias';
    }
    return OnsetEstimate(minDays: adjMin, maxDays: adjMax, explanation: explanation);
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}
