import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/DiseaseCase.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/ImagePreview.dart';
import '../widgets/PredictionList.dart';

class HealthResult extends StatelessWidget {
  const HealthResult({super.key});

  Future<void> _detectDisease(BuildContext context) async {
    final state = context.read<AppState>();
    final useCase = context.read<PredictDiseaseUseCase>();
    if (state.currentImage == null) return;
    state.setLoading(true);
    try {
      final result = await useCase.execute(state.currentImage!);
      if (!context.mounted) return;
      state.setDiseaseResult(result);
      state.push(Screen.diseaseResult);
      state.setError(null);
    } catch (e) {
      if (context.mounted) state.setError('Error modelo 2: $e');
    } finally {
      state.setLoading(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.healthResult;
        if (result == null) return const Center(child: Text('No result'));
        final isHealthy =
            result.topPrediction.label.toLowerCase().contains('healthy');

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Soya: sana o enferma',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentDark,
                ),
              ),
              const SizedBox(height: 12),
              ImagePreview(imageFile: state.currentImage),
              const SizedBox(height: 12),
              Text(
                'Mayor probabilidad: ${result.topPrediction.label} (${(result.topPrediction.confidence * 100).toStringAsFixed(1)}%)',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              PredictionList(predictions: result.predictions),
              const SizedBox(height: 12),
              isHealthy
                  ? _buildHealthySummary()
                  : _buildDiseasedActions(context, state),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHealthySummary() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'La soya fue detectada como SANA. El flujo termina aquí.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            color: Colors.green,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _buildDiseasedActions(BuildContext context, AppState state) =>
      ElevatedButton.icon(
        onPressed: () => _detectDisease(context),
        icon: const Icon(Icons.science),
        label: state.isLoading
            ? const Text('Analizando...')
            : const Text('Detectar enfermedad'),
        style: AppTheme.elevatedButtonStyle(AppTheme.accent),
      );
}
