import 'package:flutter/material.dart';
import '../../domain/ZoneAnalysis.dart';
import '../../domain/ZoneDetection.dart';
import '../LabelNames.dart';

class ZoneOverlay extends StatelessWidget {
  final ZoneAnalysis analysis;
  final Widget imageChild;

  const ZoneOverlay({super.key, required this.analysis, required this.imageChild});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (ctx, constraints) {
      final maxW = constraints.maxWidth;
      final imgAspect = analysis.imageHeight == 0
          ? 1.0
          : analysis.imageWidth / analysis.imageHeight;
      final displayW = maxW;
      final displayH = displayW / imgAspect;
      final scaleX = analysis.imageWidth == 0 ? 1.0 : displayW / analysis.imageWidth;
      final scaleY = analysis.imageHeight == 0 ? 1.0 : displayH / analysis.imageHeight;

      return SizedBox(
        width: displayW,
        height: displayH,
        child: Stack(fit: StackFit.expand, children: [
          imageChild,
          IgnorePointer(
            child: CustomPaint(
              painter: _ZonePainter(
                zones: analysis.zones,
                scaleX: scaleX,
                scaleY: scaleY,
              ),
            ),
          ),
        ]),
      );
    });
  }
}

class _ZonePainter extends CustomPainter {
  final List<ZoneDetection> zones;
  final double scaleX;
  final double scaleY;

  _ZonePainter({required this.zones, required this.scaleX, required this.scaleY});

  static const Map<String, Color> _colors = {
    'bacterianas': Color(0xFFFFA000),
    'fungicas': Color(0xFF5050FF),
    'roya': Color(0xFFD32F2F),
    'virales': Color(0xFF9C27B0),
    'plagas_insectos': Color(0xFF00BCD4),
  };

  Color _colorFor(String pathogen) =>
      _colors[pathogen.toLowerCase()] ?? Colors.orange;

  double _strokeFor(String level) {
    switch (level.toLowerCase()) {
      case 'minima':
        return 1.5;
      case 'leve':
        return 2.0;
      case 'moderada':
        return 2.5;
      case 'severa':
        return 3.5;
      case 'critica':
        return 4.5;
      default:
        return 2.0;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    final textStyle = const TextStyle(
      color: Colors.white,
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    for (final z in zones) {
      final color = _colorFor(z.pathogenClass);
      final rect = Rect.fromLTWH(
        z.bbox.left * scaleX,
        z.bbox.top * scaleY,
        z.bbox.width * scaleX,
        z.bbox.height * scaleY,
      );

      final stroke = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeFor(z.severityLevel)
        ..color = color;
      canvas.drawRect(rect, stroke);

      final labelText = '${labelToEs(z.pathogenClass)} ${z.severityPct.toStringAsFixed(0)}%';
      final tp = TextPainter(
        text: TextSpan(text: labelText, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: rect.width);

      final bgPaint = Paint()..color = color.withValues(alpha: 0.85);
      final tagRect = Rect.fromLTWH(
        rect.left,
        rect.top,
        tp.width + 6,
        tp.height + 2,
      );
      canvas.drawRect(tagRect, bgPaint);
      tp.paint(canvas, Offset(rect.left + 3, rect.top + 1));
    }
  }

  @override
  bool shouldRepaint(covariant _ZonePainter old) =>
      old.zones != zones || old.scaleX != scaleX || old.scaleY != scaleY;
}
