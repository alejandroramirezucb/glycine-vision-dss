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
    final bytes = patch.getBytes(order: img.ChannelOrder.rgb);
    final total = patch.width * patch.height;
    var healthy = 0;
    var diseased = 0;

    for (var i = 0; i < bytes.length; i += 3) {
      final r = bytes[i];
      final g = bytes[i + 1];
      final b = bytes[i + 2];
      final hsv = _rgbToHsvCv(r, g, b);
      if (_inGreen(hsv[0], hsv[1], hsv[2])) {
        healthy++;
      } else if (_inLesion(hsv[0], hsv[1], hsv[2]) || _inNecro(hsv[0], hsv[1], hsv[2])) {
        diseased++;
      }
    }

    final leaf = healthy + diseased;
    final bg = total - leaf;
    final pct = leaf > total * 0.1
        ? (diseased / leaf * 100).clamp(0.0, 100.0)
        : 0.0;
    final pctR = double.parse(pct.toStringAsFixed(1));

    return SeverityResult(
      percent: pctR,
      level: _levelFromPct(pctR),
      urgencia: _urgencyFromPct(pctR),
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

  String _levelFromPct(double pct) {
    if (pct < 5) return 'minima';
    if (pct < 15) return 'leve';
    if (pct < 35) return 'moderada';
    if (pct < 60) return 'severa';
    return 'critica';
  }

  String _urgencyFromPct(double pct) {
    if (pct < 5) return 'Solo monitoreo preventivo';
    if (pct < 15) return 'Aplicacion preventiva recomendada';
    if (pct < 35) return 'Tratamiento necesario en 48-72 horas';
    if (pct < 60) return 'Tratamiento urgente - aplicar hoy';
    return 'Emergencia fitosanitaria - accion inmediata';
  }
}
