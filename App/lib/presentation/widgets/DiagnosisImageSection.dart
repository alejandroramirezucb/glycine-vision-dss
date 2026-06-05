import 'package:flutter/material.dart';
import '../../domain/DiagnoseResult.dart';
import '../Theme.dart';
import 'DiseaseLegend.dart';
import 'ImagePreview.dart';
import 'SegmentationOverlay.dart';

class DiagnosisImageSection extends StatefulWidget {
  final dynamic image;
  final DiagnoseResult result;

  const DiagnosisImageSection({
    super.key,
    required this.image,
    required this.result,
  });

  @override
  State<DiagnosisImageSection> createState() => _DiagnosisImageSectionState();
}

class _DiagnosisImageSectionState extends State<DiagnosisImageSection> {
  bool _showSeg = true;

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final preview = ImagePreview(imageFile: widget.image, height: null);

    Widget overlay;
    if (result.hasSegmentation && _showSeg) {
      final aspect = result.imageHeight > 0
          ? result.imageWidth / result.imageHeight
          : 1.0;
      overlay = SegmentationOverlay(
        rgbaMask: result.diseaseColoredMask!,
        imageChild: preview,
        aspectRatio: aspect,
      );
    } else {
      overlay = preview;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(AppTheme.radiusImg),
          child: Stack(
            children: [
              InteractiveViewer(
                minScale: 1.0,
                maxScale: 6.0,
                child: overlay,
              ),
              if (result.hasSegmentation)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _SegToggle(
                    active: _showSeg,
                    onToggle: () => setState(() => _showSeg = !_showSeg),
                  ),
                ),
            ],
          ),
        ),
        if (result.hasSegmentation && _showSeg && result.findings.isNotEmpty) ...[
          const SizedBox(height: 8),
          DiseaseLegend(findings: result.findings),
        ],
      ],
    );
  }
}

class _SegToggle extends StatefulWidget {
  final bool active;
  final VoidCallback onToggle;

  const _SegToggle({required this.active, required this.onToggle});

  @override
  State<_SegToggle> createState() => _SegToggleState();
}

class _SegToggleState extends State<_SegToggle> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onToggle();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: AppTheme.animFast,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: widget.active
                ? AppTheme.accentDark.withValues(alpha: 0.88)
                : Colors.black54,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.active ? Icons.layers_rounded : Icons.layers_clear_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 4),
              const Text(
                'SEG',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
