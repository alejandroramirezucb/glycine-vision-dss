import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class SeverityResult {
  final double percent;
  final String level;
  final Uint8List mask3;
  final double clorosisPct;
  final double necrosisPct;
  final double defoliacionPct;

  const SeverityResult({
    required this.percent,
    required this.level,
    required this.mask3,
    required this.clorosisPct,
    required this.necrosisPct,
    required this.defoliacionPct,
  });
}

class SeverityCalculator {
  static const int _size = 256;
  static const int _greenAMax = 123;
  static const int _chlorosisBMin = 150;
  static const int _chlorosisLMin = 110;
  static const int _necrosisLMax = 130;
  static const int _necrosisBMin = 130;
  static const int _soilAbTol = 14;
  static const int _soilLMin = 150;

  const SeverityCalculator();

  SeverityResult analyze(img.Image norm256, Uint8List leaf256) {
    final bytes = norm256.getBytes(order: img.ChannelOrder.rgb);
    final n = _size * _size;
    final symptomatic = Uint8List(n);
    final reachable = _externalBackground(leaf256);
    var clorosis = 0, necrosis = 0, holes = 0, leafArea = 0;

    for (var i = 0; i < n; i++) {
      final lab = _rgbToLab8(bytes[i * 3], bytes[i * 3 + 1], bytes[i * 3 + 2]);
      final l = lab[0], a = lab[1], b = lab[2];
      if (leaf256[i] == 1) {
        leafArea++;
        final green = a < _greenAMax;
        if (!green && b > _chlorosisBMin && l > _chlorosisLMin) {
          symptomatic[i] = 1;
          clorosis++;
        } else if (!green && l < _necrosisLMax && b > _necrosisBMin) {
          symptomatic[i] = 1;
          necrosis++;
        }
      } else if (reachable[i] == 0 &&
          (a - 128).abs() < _soilAbTol &&
          (b - 128).abs() < _soilAbTol + 6 &&
          l > _soilLMin) {
        symptomatic[i] = 1;
        holes++;
      }
    }

    var symptCount = 0;
    final mask3 = Uint8List(n);
    for (var i = 0; i < n; i++) {
      if (leaf256[i] == 1) mask3[i] = 1;
      if (symptomatic[i] == 1) {
        mask3[i] = 2;
        symptCount++;
      }
    }

    final expected = (leafArea + holes) == 0 ? 1 : (leafArea + holes);
    final pct = (symptCount / expected * 100).clamp(0.0, 100.0);
    return SeverityResult(
      percent: double.parse(pct.toStringAsFixed(1)),
      level: _levelFromPct(pct),
      mask3: mask3,
      clorosisPct: double.parse((clorosis / expected * 100).toStringAsFixed(1)),
      necrosisPct: double.parse((necrosis / expected * 100).toStringAsFixed(1)),
      defoliacionPct: double.parse((holes / expected * 100).toStringAsFixed(1)),
    );
  }

  Uint8List _externalBackground(Uint8List leaf) {
    final reachable = Uint8List(leaf.length);
    final queue = Int32List(leaf.length);
    var head = 0, tail = 0;
    void seed(int i) {
      if (leaf[i] == 0 && reachable[i] == 0) {
        reachable[i] = 1;
        queue[tail++] = i;
      }
    }

    for (var x = 0; x < _size; x++) {
      seed(x);
      seed((_size - 1) * _size + x);
    }
    for (var y = 0; y < _size; y++) {
      seed(y * _size);
      seed(y * _size + _size - 1);
    }
    while (head < tail) {
      final px = queue[head++];
      final x = px % _size;
      for (final d in const [-1, 1, -_size, _size]) {
        final nx = px + d;
        if (d == -1 && x == 0) continue;
        if (d == 1 && x == _size - 1) continue;
        if (nx < 0 || nx >= leaf.length) continue;
        if (leaf[nx] == 0 && reachable[nx] == 0) {
          reachable[nx] = 1;
          queue[tail++] = nx;
        }
      }
    }
    return reachable;
  }

  List<int> _rgbToLab8(int r, int g, int b) {
    final rl = _lin(r / 255.0), gl = _lin(g / 255.0), bl = _lin(b / 255.0);
    final x = (0.4124 * rl + 0.3576 * gl + 0.1805 * bl) / 0.95047;
    final y = 0.2126 * rl + 0.7152 * gl + 0.0722 * bl;
    final z = (0.0193 * rl + 0.1192 * gl + 0.9505 * bl) / 1.08883;
    final fx = _f(x), fy = _f(y), fz = _f(z);
    final lStar = 116 * fy - 16;
    final aStar = 500 * (fx - fy);
    final bStar = 200 * (fy - fz);
    return [
      (lStar * 255 / 100).round().clamp(0, 255),
      (aStar + 128).round().clamp(0, 255),
      (bStar + 128).round().clamp(0, 255),
    ];
  }

  double _lin(double c) => c <= 0.04045 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();
  double _f(double t) => t > 0.008856 ? math.pow(t, 1 / 3).toDouble() : 7.787 * t + 16 / 116;

  String _levelFromPct(double pct) {
    if (pct < 5) return 'minima';
    if (pct < 15) return 'leve';
    if (pct < 35) return 'moderada';
    if (pct < 60) return 'severa';
    return 'critica';
  }
}
