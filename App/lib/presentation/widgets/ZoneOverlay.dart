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
                analysis: analysis,
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
  final ZoneAnalysis analysis;
  final double scaleX;
  final double scaleY;

  _ZonePainter({required this.analysis, required this.scaleX, required this.scaleY});

  static Color _fillFor(String level) => switch (level.toLowerCase()) {
        'minima' => const Color(0xFFFFEB3B).withValues(alpha: 0.18),
        'leve' => const Color(0xFFFFC107).withValues(alpha: 0.26),
        'moderada' => const Color(0xFFFF9800).withValues(alpha: 0.36),
        'severa' => const Color(0xFFFF5722).withValues(alpha: 0.44),
        'critica' => const Color(0xFFF44336).withValues(alpha: 0.52),
        _ => const Color(0xFFFF9800).withValues(alpha: 0.30),
      };

  static Color _borderFor(String level) => switch (level.toLowerCase()) {
        'minima' => const Color(0xFFFFD600),
        'leve' => const Color(0xFFFFB300),
        'moderada' => const Color(0xFFE65100),
        'severa' => const Color(0xFFDD2C00),
        'critica' => const Color(0xFFB71C1C),
        _ => const Color(0xFFE65100),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final patchSize = analysis.patchSize;
    final stride = patchSize ~/ 2;
    final patchW = patchSize * scaleX;
    final patchH = patchSize * scaleY;

    final zoneMap = <String, ZoneDetection>{};
    for (final z in analysis.zones) {
      zoneMap['${z.bbox.left.toInt()},${z.bbox.top.toInt()}'] = z;
    }

    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = Colors.white.withValues(alpha: 0.18);

    for (var y = 0; y < analysis.imageHeight; y += stride) {
      for (var x = 0; x < analysis.imageWidth; x += stride) {
        final cellW = (x + patchSize > analysis.imageWidth
                ? analysis.imageWidth - x
                : patchSize)
            .toDouble();
        final cellH = (y + patchSize > analysis.imageHeight
                ? analysis.imageHeight - y
                : patchSize)
            .toDouble();
        final rect = Rect.fromLTWH(
          x * scaleX,
          y * scaleY,
          cellW * scaleX,
          cellH * scaleY,
        );
        final zone = zoneMap['$x,$y'];

        if (zone != null) {
          canvas.drawRect(
            rect,
            Paint()
              ..color = _fillFor(zone.severityLevel)
              ..style = PaintingStyle.fill,
          );
          canvas.drawRect(
            rect,
            Paint()
              ..color = _borderFor(zone.severityLevel)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1.5,
          );
          _drawLabel(canvas, rect, zone);
        } else {
          canvas.drawRect(rect, gridPaint);
        }
      }
    }
  }

  void _drawLabel(Canvas canvas, Rect rect, ZoneDetection zone) {
    // Skip label if zone too small (< 30px width)
    if (rect.width < 30) return;

    final label =
        '${labelToEs(zone.pathogenClass)} ${zone.severityPct.toStringAsFixed(0)}%';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          shadows: [
            Shadow(
              color: Colors.black.withValues(alpha: 0.65),
              blurRadius: 2,
            )
          ],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: rect.width - 4);

    final bgPaint = Paint()
      ..color = _borderFor(zone.severityLevel).withValues(alpha: 0.80);
    final tagRect = Rect.fromLTWH(
      rect.left,
      rect.top,
      tp.width + 6,
      tp.height + 3,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(tagRect, const Radius.circular(2)),
      bgPaint,
    );
    tp.paint(canvas, Offset(rect.left + 3, rect.top + 1.5));
  }

  @override
  bool shouldRepaint(covariant _ZonePainter old) =>
      old.analysis != analysis || old.scaleX != scaleX || old.scaleY != scaleY;
}
