import 'dart:typed_data';
import '../domain/Zone.dart';

class DiseaseColorizer {
  static const int _maskSize = 256;
  static const int _healthyAlpha = 80;
  static const int _diseasedAlpha = 153;
  static const ({int r, int g, int b}) _healthyRgb = (r: 34, g: 197, b: 94);

  static Uint8List build(Uint8List mask256, List<ActiveDisease> diseases) {
    final rgba = Uint8List(_maskSize * _maskSize * 4);
    if (mask256.isEmpty) return rgba;

    final dominant = _dominant(diseases);

    for (var i = 0; i < mask256.length; i++) {
      final cls = mask256[i];
      final px = i * 4;
      if (cls == 0) {
        rgba[px + 3] = 255;
        continue;
      }
      if (cls == 1) {
        rgba[px] = _healthyRgb.r;
        rgba[px + 1] = _healthyRgb.g;
        rgba[px + 2] = _healthyRgb.b;
        rgba[px + 3] = _healthyAlpha;
      } else {
        final col = dominant != null ? _colorFor(dominant.pathogenClass) : _healthyRgb;
        rgba[px] = col.r;
        rgba[px + 1] = col.g;
        rgba[px + 2] = col.b;
        rgba[px + 3] = _diseasedAlpha;
      }
    }
    return rgba;
  }

  static ActiveDisease? _dominant(List<ActiveDisease> diseases) {
    if (diseases.isEmpty) return null;
    return diseases.reduce((a, b) => a.probability >= b.probability ? a : b);
  }

  static ({int r, int g, int b}) _colorFor(String cls) =>
      switch (cls.toLowerCase()) {
        'roya' => (r: 255, g: 111, b: 0),
        'fungicas' => (r: 27, g: 94, b: 32),
        'bacterianas' => (r: 13, g: 71, b: 161),
        'virales' => (r: 106, g: 27, b: 154),
        'plagas_insectos' => (r: 109, g: 76, b: 65),
        _ => (r: 69, g: 90, b: 100),
      };
}
