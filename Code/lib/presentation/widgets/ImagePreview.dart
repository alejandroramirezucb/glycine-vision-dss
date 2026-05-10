import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../Theme.dart';

class ImagePreview extends StatelessWidget {
  final XFile? imageFile;

  const ImagePreview({super.key, this.imageFile});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.imgHeight,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      ),
      child: imageFile != null ? _buildImage() : _buildPlaceholder(),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      return Image.network(imageFile!.path, fit: BoxFit.contain);
    }
    return Image.file(File(imageFile!.path), fit: BoxFit.contain);
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
