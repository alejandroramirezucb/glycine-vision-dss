import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Theme.dart';

class ImagePreview extends StatelessWidget {
  final XFile? imageFile;
  final double? height;
  final BoxFit fit;

  const ImagePreview({
    super.key,
    this.imageFile,
    this.height = AppTheme.imgHeight,
    this.fit = BoxFit.contain,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      ),
      child: imageFile != null ? _buildImage() : _buildPlaceholder(),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(imageFile!.path, fit: fit);
    }
    return Image.file(File(imageFile!.path), fit: fit);
  }

  Widget _buildPlaceholder() => Container(
        color: const Color(0xFFD4E2E6),
        alignment: Alignment.center,
        child: const Text(
          'Sin imagen seleccionada',
          style: TextStyle(
            color: AppTheme.textMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}
