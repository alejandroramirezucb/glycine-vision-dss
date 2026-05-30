import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../application/DiagnoseUseCase.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/ImagePreview.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _picker = ImagePicker();

  Future<void> _pickFromSource(ImageSource source) async {
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 400,
      maxHeight: 400,
      imageQuality: 88,
    );
    if (file != null && mounted) {
      context.read<AppState>().selectImage(file);
    }
  }

  Future<void> _diagnose() async {
    final state = context.read<AppState>();
    if (state.currentImage == null) {
      state.setError('Primero selecciona o captura una imagen.');
      return;
    }
    state.setError(null);
    state.setLoading(true);
    try {
      final coords = await _resolveCoords();
      final useCase = context.read<DiagnoseUseCase>();
      final result = await useCase.execute(
        state.currentImage!,
        lat: coords?.$1,
        lon: coords?.$2,
      );
      if (!mounted) return;
      state.setDiagnoseResult(result);
      state.push(Screen.diagnoseResult);
    } catch (e) {
      if (mounted) state.setError('Error en el diagnóstico: $e');
    } finally {
      if (mounted) state.setLoading(false);
    }
  }

  Future<(double, double)?> _resolveCoords() async {
    try {
      final permission = await Geolocator.requestPermission();
      if (permission != LocationPermission.always &&
          permission != LocationPermission.whileInUse) {
        return null;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(timeLimit: Duration(seconds: 6)),
      );
      return (position.latitude, position.longitude);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),
          Text(
            state.currentImage == null
                ? 'Sube o captura una hoja de soya'
                : 'Imagen lista para diagnosticar',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: state.currentImage == null
                  ? AppTheme.textPrimary
                  : AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 14),
          _UploadArea(
            imageFile: state.currentImage,
            isLoading: state.isLoading,
          ),
          if (state.error != null) ...[
            const SizedBox(height: 10),
            _ErrorBanner(message: state.error!),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickFromSource(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined, size: 18),
                  label: const Text('Galería'),
                  style: AppTheme.elevatedButtonStyle(AppTheme.accent),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _pickFromSource(ImageSource.camera),
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('Cámara'),
                  style: AppTheme.elevatedButtonStyle(AppTheme.accentLight),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: state.currentImage != null && !state.isLoading
                ? _diagnose
                : null,
            icon: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.biotech_outlined, size: 18),
            label: Text(state.isLoading ? 'Analizando...' : 'Diagnosticar'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accentDark),
          ),
        ],
      ),
    );
  }
}

class _UploadArea extends StatelessWidget {
  final dynamic imageFile;
  final bool isLoading;

  const _UploadArea({required this.imageFile, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _PlaceholderFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: AppTheme.accent, strokeWidth: 2),
            SizedBox(height: 12),
            Text(
              'Analizando imagen...',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    if (imageFile == null) {
      return _PlaceholderFrame(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.add_photo_alternate_outlined,
                size: 40, color: AppTheme.accent),
            SizedBox(height: 8),
            Text(
              'Selecciona una imagen\npara comenzar',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: AppTheme.textMuted,
                  fontSize: 13,
                  height: 1.5),
            ),
          ],
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      child: ImagePreview(imageFile: imageFile),
    );
  }
}

class _PlaceholderFrame extends StatelessWidget {
  final Widget child;
  const _PlaceholderFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppTheme.imgHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusImg),
        border: Border.all(
          color: AppTheme.accent.withValues(alpha: 0.4),
          width: 1.5,
          strokeAlign: BorderSide.strokeAlignInside,
        ),
        color: AppTheme.accent.withValues(alpha: 0.04),
      ),
      child: Center(child: child),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: Colors.red.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
