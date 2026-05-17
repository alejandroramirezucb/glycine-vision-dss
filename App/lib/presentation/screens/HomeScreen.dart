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
          const SizedBox(height: 12),
          const Text(
            'Selecciona o captura una imagen de soya',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ImagePreview(imageFile: state.currentImage),
          const SizedBox(height: 14),
          if (state.error != null) _ErrorBanner(message: state.error!),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () => _pickFromSource(ImageSource.gallery),
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir imagen'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accent),
          ),
          const SizedBox(height: 9),
          ElevatedButton.icon(
            onPressed: () => _pickFromSource(ImageSource.camera),
            icon: const Icon(Icons.camera_alt),
            label: const Text('Abrir cámara'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accentLight),
          ),
          const SizedBox(height: 9),
          ElevatedButton.icon(
            onPressed:
                state.currentImage != null && !state.isLoading ? _diagnose : null,
            icon: const Icon(Icons.medical_information_outlined),
            label: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Diagnosticar'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accentDark),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Colors.red, fontSize: 12),
      ),
    );
  }
}
