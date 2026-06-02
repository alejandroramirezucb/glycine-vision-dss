import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../domain/Zone.dart';

class DiseaseColorizer {
  static const int _maskSize = 256;
  static const _healthyRgba = (r: 34, g: 197, b: 94, a: 80);
  static const int _diseasedAlpha = 153;

  static Uint8List build(
    Uint8List mask256,
    img.Image source,
    List<ActiveDisease> diseases,
  ) {
    final rgba = Uint8List(_maskSize * _maskSize * 4);
    if (diseases.isEmpty) return rgba;
    final bytes = source.getBytes(order: img.ChannelOrder.rgb);
    for (var i = 0; i < mask256.length; i++) {
      final cls = mask256[i];
      if (cls == 0) continue;
      final px = i * 4;
      if (cls == 1) {
        rgba[px] = _healthyRgba.r;
        rgba[px + 1] = _healthyRgba.g;
        rgba[px + 2] = _healthyRgba.b;
        rgba[px + 3] = _healthyRgba.a;
        continue;
      }
      final srcPx = i * 3;
      final hsv = _toHsv(bytes[srcPx], bytes[srcPx + 1], bytes[srcPx + 2]);
      final best = _bestDisease(hsv, diseases);
      if (best != null) {
        final col = _colorFor(best.pathogenClass);
        rgba[px] = col.r;
        rgba[px + 1] = col.g;
        rgba[px + 2] = col.b;
        rgba[px + 3] = _diseasedAlpha;
      }
    }
    return rgba;
  }

  static Uint8List buildFromMaskOnly(
    Uint8List mask256,
    List<ActiveDisease> diseases,
  ) {
    final rgba = Uint8List(_maskSize * _maskSize * 4);
    if (diseases.isEmpty) return rgba;

    final sorted = List<ActiveDisease>.from(diseases)
      ..sort((a, b) => b.probability.compareTo(a.probability));

    final diseasedIndices = <int>[];
    for (var i = 0; i < mask256.length; i++) {
      if (mask256[i] == 1) {
        final px = i * 4;
        rgba[px] = _healthyRgba.r;
        rgba[px + 1] = _healthyRgba.g;
        rgba[px + 2] = _healthyRgba.b;
        rgba[px + 3] = _healthyRgba.a;
      } else if (mask256[i] == 2) {
        diseasedIndices.add(i);
      }
    }

    if (diseasedIndices.isEmpty) return rgba;

    final totalProb = sorted.fold(0.0, (s, d) => s + d.probability);
    var offset = 0;
    for (var di = 0; di < sorted.length; di++) {
      final disease = sorted[di];
      final share = disease.probability / totalProb;
      final count = di == sorted.length - 1
          ? diseasedIndices.length - offset
          : (share * diseasedIndices.length).round();
      final col = _colorFor(disease.pathogenClass);
      for (var k = offset; k < offset + count && k < diseasedIndices.length; k++) {
        final px = diseasedIndices[k] * 4;
        rgba[px] = col.r;
        rgba[px + 1] = col.g;
        rgba[px + 2] = col.b;
        rgba[px + 3] = _diseasedAlpha;
      }
      offset += count;
    }

    return rgba;
  }

  static ActiveDisease? _bestDisease(List<int> hsv, List<ActiveDisease> diseases) {
    var bestScore = -1.0;
    ActiveDisease? best;
    for (final d in diseases) {
      final score = _hsvScore(hsv, d.pathogenClass) * d.probability;
      if (score > bestScore) {
        bestScore = score;
        best = d;
      }
    }
    return best;
  }

  static double _hsvScore(List<int> hsv, String pathogenClass) {
    final h = hsv[0];
    final s = hsv[1];
    final v = hsv[2];
    return switch (pathogenClass.toLowerCase()) {
      'roya' => (h >= 5 && h <= 15 && s > 100 && v >= 60 && v <= 200) ? 1.0 : 0.05,
      'bacterianas' => (h >= 10 && h <= 25 && s >= 50 && s <= 200 && v >= 60 && v <= 220) ? 1.0 : 0.05,
      'fungicas' => (s < 60 || v < 60) ? 1.0 : 0.05,
      'virales' => (h >= 15 && h <= 30 && s >= 40 && s <= 180 && v > 80) ? 1.0 : 0.05,
      'plagas_insectos' => v < 50 ? 1.0 : 0.05,
      _ => 0.1,
    };
  }

  static ({int r, int g, int b}) _colorFor(String pathogenClass) =>
      switch (pathogenClass.toLowerCase()) {
        'roya' => (r: 255, g: 111, b: 0),
        'fungicas' => (r: 27, g: 94, b: 32),
        'bacterianas' => (r: 13, g: 71, b: 161),
        'virales' => (r: 74, g: 20, b: 140),
        'plagas_insectos' => (r: 183, g: 28, b: 28),
        _ => (r: 191, g: 54, b: 12),
      };

  static List<int> _toHsv(int r, int g, int b) {
    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final delta = maxC - minC;
    int h;
    if (delta == 0) {
      h = 0;
    } else if (maxC == r) {
      h = ((60 * (g - b) / delta) % 360).round();
    } else if (maxC == g) {
      h = ((60 * (b - r) / delta) + 120).round();
    } else {
      h = ((60 * (r - g) / delta) + 240).round();
    }
    if (h < 0) h += 360;
    return [
      (h / 2).round(),
      maxC == 0 ? 0 : ((delta / maxC) * 255).round(),
      maxC,
    ];
  }
}
