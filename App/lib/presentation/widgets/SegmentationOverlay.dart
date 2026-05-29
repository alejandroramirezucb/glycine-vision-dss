import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SegmentationOverlay extends StatefulWidget {
  final Uint8List mask256;
  final Widget imageChild;
  final double aspectRatio;

  const SegmentationOverlay({
    super.key,
    required this.mask256,
    required this.imageChild,
    this.aspectRatio = 1.0,
  });

  @override
  State<SegmentationOverlay> createState() => _SegmentationOverlayState();
}

class _SegmentationOverlayState extends State<SegmentationOverlay> {
  static const int _maskSize = 256;
  static const _healthyColor = (r: 34, g: 197, b: 94, a: 80);
  static const _diseasedColor = (r: 249, g: 115, b: 22, a: 153);

  ui.Image? _maskImage;
  Uint8List? _lastMask;

  @override
  void initState() {
    super.initState();
    _buildMaskImage(widget.mask256);
  }

  @override
  void didUpdateWidget(SegmentationOverlay old) {
    super.didUpdateWidget(old);
    if (!identical(widget.mask256, _lastMask)) {
      _buildMaskImage(widget.mask256);
    }
  }

  @override
  void dispose() {
    _maskImage?.dispose();
    super.dispose();
  }

  void _buildMaskImage(Uint8List mask) {
    _lastMask = mask;
    final rgba = Uint8List(_maskSize * _maskSize * 4);
    for (var i = 0; i < _maskSize * _maskSize; i++) {
      final c = mask[i];
      if (c == 0) continue;
      final px = i * 4;
      final col = c == 1 ? _healthyColor : _diseasedColor;
      rgba[px] = col.r;
      rgba[px + 1] = col.g;
      rgba[px + 2] = col.b;
      rgba[px + 3] = col.a;
    }
    ui.decodeImageFromPixels(
      rgba,
      _maskSize,
      _maskSize,
      ui.PixelFormat.rgba8888,
      (img) {
        if (!mounted) {
          img.dispose();
          return;
        }
        setState(() {
          _maskImage?.dispose();
          _maskImage = img;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      final w = constraints.maxWidth;
      final h = widget.aspectRatio > 0 ? w / widget.aspectRatio : w;
      return SizedBox(
        width: w,
        height: h,
        child: Stack(
          fit: StackFit.expand,
          children: [
            widget.imageChild,
            if (_maskImage != null)
              IgnorePointer(
                child: CustomPaint(
                  painter: _MaskPainter(_maskImage!),
                ),
              ),
          ],
        ),
      );
    });
  }
}

class _MaskPainter extends CustomPainter {
  final ui.Image image;

  _MaskPainter(this.image);

  @override
  void paint(Canvas canvas, Size size) {
    final src = Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble());
    final dst = Rect.fromLTWH(0, 0, size.width, size.height);
    canvas.drawImageRect(
      image,
      src,
      dst,
      Paint()..filterQuality = FilterQuality.none,
    );
  }

  @override
  bool shouldRepaint(_MaskPainter old) => old.image != image;
}
