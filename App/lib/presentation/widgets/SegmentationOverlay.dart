import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

class SegmentationOverlay extends StatefulWidget {
  final Uint8List rgbaMask;
  final Widget imageChild;
  final double aspectRatio;

  const SegmentationOverlay({
    super.key,
    required this.rgbaMask,
    required this.imageChild,
    this.aspectRatio = 1.0,
  });

  @override
  State<SegmentationOverlay> createState() => _SegmentationOverlayState();
}

class _SegmentationOverlayState extends State<SegmentationOverlay> {
  static const int _maskSize = 256;

  ui.Image? _maskImage;
  Uint8List? _lastMask;

  @override
  void initState() {
    super.initState();
    _buildMaskImage(widget.rgbaMask);
  }

  @override
  void didUpdateWidget(SegmentationOverlay old) {
    super.didUpdateWidget(old);
    if (!identical(widget.rgbaMask, _lastMask)) {
      _buildMaskImage(widget.rgbaMask);
    }
  }

  @override
  void dispose() {
    _maskImage?.dispose();
    super.dispose();
  }

  void _buildMaskImage(Uint8List rgba) {
    _lastMask = rgba;
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
    final src = Rect.fromLTWH(
        0, 0, image.width.toDouble(), image.height.toDouble());
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
