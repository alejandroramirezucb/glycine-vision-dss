import 'package:image/image.dart' as img;

class SeverityResult {
  final double percent;
  final String level;
  final String urgencia;
  final int healthyPx;
  final int diseasedPx;
  final int bgPx;

  const SeverityResult({
    required this.percent,
    required this.level,
    required this.urgencia,
    required this.healthyPx,
    required this.diseasedPx,
    required this.bgPx,
  });
}

class SeverityCalculator {
  const SeverityCalculator();

  SeverityResult calculate(img.Image patch) {
    final w = patch.width;
    final h = patch.height;
    var healthy = 0;
    var diseased = 0;
    final total = w * h;

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = patch.getPixelSafe(x, y);
        final r = p.r.toInt() & 0xFF;
        final g = p.g.toInt() & 0xFF;
        final b = p.b.toInt() & 0xFF;
        final hsv = _rgbToHsvCv(r, g, b);
        final hh = hsv[0];
        final ss = hsv[1];
        final vv = hsv[2];

        if (_inGreen(hh, ss, vv)) {
          healthy++;
        } else if (_inLesion(hh, ss, vv) || _inNecro(hh, ss, vv)) {
          diseased++;
        }
      }
    }

    final leaf = healthy + diseased;
    final bg = total - leaf;

    double pct;
    if (leaf > total * 0.1) {
      pct = (diseased / leaf) * 100.0;
    } else {
      pct = 0.0;
    }
    if (pct > 100) pct = 100;
    final pctR = double.parse(pct.toStringAsFixed(1));

    String level;
    String urg;
    if (pctR < 5) {
      level = 'minima';
      urg = 'Solo monitoreo preventivo';
    } else if (pctR < 15) {
      level = 'leve';
      urg = 'Aplicacion preventiva recomendada';
    } else if (pctR < 35) {
      level = 'moderada';
      urg = 'Tratamiento necesario en 48-72 horas';
    } else if (pctR < 60) {
      level = 'severa';
      urg = 'Tratamiento urgente - aplicar hoy';
    } else {
      level = 'critica';
      urg = 'Emergencia fitosanitaria - accion inmediata';
    }

    return SeverityResult(
      percent: pctR,
      level: level,
      urgencia: urg,
      healthyPx: healthy,
      diseasedPx: diseased,
      bgPx: bg,
    );
  }

  bool _inGreen(int h, int s, int v) =>
      h >= 30 && h <= 85 && s >= 40 && v >= 40;

  bool _inLesion(int h, int s, int v) {
    final inHue1 = h >= 10 && h <= 30 && s >= 50 && v >= 20 && v <= 200;
    final inHue2 = h <= 10 && s >= 50 && v >= 20 && v <= 180;
    return inHue1 || inHue2;
  }

  bool _inNecro(int h, int s, int v) => s <= 80 && v <= 60;

  List<int> _rgbToHsvCv(int r, int g, int b) {
    final maxC = (r > g ? (r > b ? r : b) : (g > b ? g : b));
    final minC = (r < g ? (r < b ? r : b) : (g < b ? g : b));
    final delta = maxC - minC;

    int h = 0;
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
    final hCv = (h / 2).round();

    final s = maxC == 0 ? 0 : ((delta / maxC) * 255).round();
    final v = maxC;

    return [hCv, s, v];
  }
}
