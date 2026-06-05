import 'package:image/image.dart' as img;

class SeverityResult {
  final double percent;
  final String level;

  const SeverityResult({required this.percent, required this.level});
}

class SeverityCalculator {
  const SeverityCalculator();

  SeverityResult calculate(img.Image patch) {
    final bytes = patch.getBytes(order: img.ChannelOrder.rgb);
    final total = patch.width * patch.height;
    var healthy = 0;
    var diseased = 0;

    for (var i = 0; i < bytes.length; i += 3) {
      final hsv = _toHsv(bytes[i], bytes[i + 1], bytes[i + 2]);
      if (_isGreen(hsv[0], hsv[1], hsv[2]))
        healthy++;
      else if (_isLesion(hsv[0], hsv[1], hsv[2]) || _isNecrotic(hsv[1], hsv[2]))
        diseased++;
    }

    final leaf = healthy + diseased;
    final pct = leaf > total * 0.1 ? (diseased / leaf * 100).clamp(0.0, 100.0) : 0.0;
    final pctR = double.parse(pct.toStringAsFixed(1));
    return SeverityResult(percent: pctR, level: _levelFromPct(pctR));
  }

  bool _isGreen(int h, int s, int v) => h >= 30 && h <= 85 && s >= 40 && v >= 40;

  bool _isLesion(int h, int s, int v) =>
      (h >= 10 && h <= 30 || h <= 10) && s >= 50 && v >= 20 && v <= 200;

  bool _isNecrotic(int s, int v) => s <= 80 && v <= 60;

  List<int> _toHsv(int r, int g, int b) {
    final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
    final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
    final delta = maxC - minC;
    int h;
    if (delta == 0)
      h = 0;
    else if (maxC == r)
      h = ((60 * (g - b) / delta) % 360).round();
    else if (maxC == g)
      h = ((60 * (b - r) / delta) + 120).round();
    else
      h = ((60 * (r - g) / delta) + 240).round();
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
}
