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
    var clorosis = 0, necrosis = 0;

    final hull = _convexHullMask(leaf256);
    var hullArea = 0;
    for (final h in hull) {
      if (h == 1) hullArea++;
    }
    if (hullArea == 0) hullArea = 1;

    for (var i = 0; i < n; i++) {
      final leaf = leaf256[i] == 1;
      if (leaf) {
        final lab = _rgbToLab8(bytes[i * 3], bytes[i * 3 + 1], bytes[i * 3 + 2]);
        final l = lab[0], a = lab[1], b = lab[2];
        final green = a < _greenAMax;
        if (!green && b > _chlorosisBMin && l > _chlorosisLMin) {
          symptomatic[i] = 1;
          clorosis++;
        } else if (!green && l < _necrosisLMax && b > _necrosisBMin) {
          symptomatic[i] = 1;
          necrosis++;
        } else if ((a - 128).abs() < _soilAbTol && (b - 128).abs() < _soilAbTol + 6 && l > _soilLMin) {
          symptomatic[i] = 1;
        }
      } else if (hull[i] == 1) {
        symptomatic[i] = 1;
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

    final pct = (symptCount / hullArea * 100).clamp(0.0, 100.0);
    final defol = symptCount - clorosis - necrosis;
    return SeverityResult(
      percent: double.parse(pct.toStringAsFixed(1)),
      level: _levelFromPct(pct),
      mask3: mask3,
      clorosisPct: double.parse((clorosis / hullArea * 100).toStringAsFixed(1)),
      necrosisPct: double.parse((necrosis / hullArea * 100).toStringAsFixed(1)),
      defoliacionPct: double.parse(((defol < 0 ? 0 : defol) / hullArea * 100).toStringAsFixed(1)),
    );
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

  Uint8List _convexHullMask(Uint8List leaf) {
    final pts = <List<int>>[];
    for (var i = 0; i < leaf.length; i++) {
      if (leaf[i] == 1) pts.add([i % _size, i ~/ _size]);
    }
    final out = Uint8List(leaf.length);
    if (pts.length < 3) {
      for (var i = 0; i < leaf.length; i++) {
        out[i] = leaf[i];
      }
      return out;
    }
    pts.sort((p, q) => p[0] != q[0] ? p[0] - q[0] : p[1] - q[1]);
    final hull = _monotoneChain(pts);
    var minY = _size, maxY = 0;
    for (final p in hull) {
      minY = math.min(minY, p[1]);
      maxY = math.max(maxY, p[1]);
    }
    for (var y = minY; y <= maxY; y++) {
      var lo = _size, hi = -1;
      for (var x = 0; x < _size; x++) {
        if (_inside(hull, x, y)) {
          if (x < lo) lo = x;
          if (x > hi) hi = x;
        }
      }
      for (var x = lo; x <= hi; x++) {
        out[y * _size + x] = 1;
      }
    }
    return out;
  }

  List<List<int>> _monotoneChain(List<List<int>> pts) {
    int cross(List<int> o, List<int> a, List<int> b) =>
        (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
    final lower = <List<int>>[];
    for (final p in pts) {
      while (lower.length >= 2 && cross(lower[lower.length - 2], lower.last, p) <= 0) lower.removeLast();
      lower.add(p);
    }
    final upper = <List<int>>[];
    for (var i = pts.length - 1; i >= 0; i--) {
      final p = pts[i];
      while (upper.length >= 2 && cross(upper[upper.length - 2], upper.last, p) <= 0) upper.removeLast();
      upper.add(p);
    }
    lower.removeLast();
    upper.removeLast();
    return [...lower, ...upper];
  }

  bool _inside(List<List<int>> hull, int x, int y) {
    var sign = 0;
    for (var i = 0; i < hull.length; i++) {
      final a = hull[i], b = hull[(i + 1) % hull.length];
      final c = (b[0] - a[0]) * (y - a[1]) - (b[1] - a[1]) * (x - a[0]);
      if (c != 0) {
        final s = c > 0 ? 1 : -1;
        if (sign == 0) {
          sign = s;
        } else if (s != sign) {
          return false;
        }
      }
    }
    return true;
  }

  String _levelFromPct(double pct) {
    if (pct < 5) return 'minima';
    if (pct < 15) return 'leve';
    if (pct < 35) return 'moderada';
    if (pct < 60) return 'severa';
    return 'critica';
  }
}
