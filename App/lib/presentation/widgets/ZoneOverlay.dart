import 'package:flutter/material.dart';
import '../../domain/DiagnoseResult.dart';
import '../../domain/Zone.dart';
import '../PathogenColors.dart';

class ZoneOverlay extends StatelessWidget {
  final DiagnoseResult result;
  final Widget imageChild;

  const ZoneOverlay({super.key, required this.result, required this.imageChild});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, c) {
      final aspect = result.imageHeight == 0
          ? 1.0
          : result.imageWidth / result.imageHeight;
      final w = c.maxWidth;
      final h = w / aspect;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(fit: StackFit.expand, children: [
          imageChild,
          IgnorePointer(
            child: CustomPaint(
              painter: _ZonePainter(result: result),
            ),
          ),
        ]),
      );
    });
  }
}

class _ZonePainter extends CustomPainter {
  static const double _fillAlpha = 0.35;
  static const double _borderWidth = 1.6;

  final DiagnoseResult result;

  _ZonePainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    if (result.imageWidth == 0 || result.imageHeight == 0) return;
    final sx = size.width / result.imageWidth;
    final sy = size.height / result.imageHeight;
    for (final zone in result.zones) {
      _paintZone(canvas, zone, sx, sy);
    }
  }

  void _paintZone(Canvas canvas, Zone zone, double sx, double sy) {
    final rect = Rect.fromLTRB(
      zone.bbox.left * sx,
      zone.bbox.top * sy,
      zone.bbox.right * sx,
      zone.bbox.bottom * sy,
    );
    final classes = zone.activeDiseases;
    if (classes.isEmpty) return;
    if (classes.length == 1) {
      _drawSolid(canvas, rect, pathogenColor(classes.first.pathogenClass));
      return;
    }
    _drawStriped(canvas, rect, classes.map((d) => d.pathogenClass).toList());
  }

  void _drawSolid(Canvas canvas, Rect rect, Color color) {
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: _fillAlpha));
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth
        ..color = color,
    );
  }

  void _drawStriped(Canvas canvas, Rect rect, List<String> classes) {
    canvas.save();
    canvas.clipRect(rect);
    final stripeWidth = rect.width / classes.length;
    for (var i = 0; i < classes.length; i++) {
      final stripeRect = Rect.fromLTWH(
        rect.left + stripeWidth * i,
        rect.top,
        stripeWidth,
        rect.height,
      );
      canvas.drawRect(
        stripeRect,
        Paint()..color = pathogenColor(classes[i]).withValues(alpha: _fillAlpha),
      );
    }
    canvas.restore();
    final accent = pathogenColor(classes.first);
    canvas.drawRect(
      rect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = _borderWidth
        ..color = accent,
    );
  }

  @override
  bool shouldRepaint(_ZonePainter old) => old.result != result;
}
