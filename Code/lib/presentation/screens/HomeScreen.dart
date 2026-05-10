import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../application/HealthCase.dart';
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

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery);
    if (file != null && mounted) {
      context.read<AppState>().selectImage(file);
    }
  }

  Future<void> _pickCamera() async {
    final file = await _picker.pickImage(source: ImageSource.camera);
    if (file != null && mounted) {
      context.read<AppState>().selectImage(file);
    }
  }

  Future<void> _detectHealth() async {
    final state = context.read<AppState>();
    final useCase = context.read<PredictHealthUseCase>();
    if (state.currentImage == null) {
      state.setError('Primero selecciona o captura una imagen.');
      return;
    }
    state.setLoading(true);
    try {
      final result = await useCase.execute(state.currentImage!);
      if (!mounted) return;
      state.setHealthResult(result);
      state.push(Screen.healthResult);
      state.setError(null);
    } catch (e) {
      if (mounted) state.setError('Error modelo 1: $e');
    } finally {
      state.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) => SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 12),
            const Text(
              'Selecciona o captura una imagen de soya',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ImagePreview(imageFile: state.currentImage),
            const SizedBox(height: 14),
            if (state.error != null) _buildErrorBanner(state.error!),
            const SizedBox(height: 12),
            _buildButtons(state),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) => Container(
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

  Widget _buildButtons(AppState state) => Column(
        children: [
          ElevatedButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Subir imagen'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accent),
          ),
          const SizedBox(height: 9),
          ElevatedButton.icon(
            onPressed: _pickCamera,
            icon: const Icon(Icons.camera_alt),
            label: const Text('Abrir cámara'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accentLight),
          ),
          const SizedBox(height: 9),
          ElevatedButton.icon(
            onPressed: state.currentImage != null && !state.isLoading
                ? _detectHealth
                : null,
            icon: const Icon(Icons.health_and_safety),
            label: state.isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Detectar salud'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accentDark),
          ),
        ],
      );
}
