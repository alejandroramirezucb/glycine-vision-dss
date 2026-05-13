import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../application/ClassifyUseCase.dart';
import '../LabelNames.dart';
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
        if (result == null) return const Center(child: Text('Sin resultado'));
        final isHealthy =
            result.topPrediction.label.toLowerCase().contains('healthy');

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Estado de la planta',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentDark,
                ),
              ),
              const SizedBox(height: 12),
              ImagePreview(imageFile: state.currentImage),
              const SizedBox(height: 16),
              _buildTopResult(result.topPrediction.label,
                  result.topPrediction.confidence, isHealthy),
              const SizedBox(height: 16),
              PredictionList(predictions: result.predictions),
              const SizedBox(height: 4),
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

  Widget _buildTopResult(String label, double confidence, bool isHealthy) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: (isHealthy ? Colors.green : AppTheme.urgentHigh)
              .withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isHealthy ? Icons.check_circle : Icons.warning_amber_rounded,
              color: isHealthy ? Colors.green : AppTheme.urgentHigh,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              '${labelToEs(label)}  •  ${(confidence * 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isHealthy ? Colors.green : AppTheme.urgentHigh,
              ),
            ),
          ],
        ),
      );

  Widget _buildHealthySummary() => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.green.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'La planta fue detectada como sana.',
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
        onPressed: state.isLoading ? null : () => _detectDisease(context),
        icon: state.isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.science),
        label: state.isLoading
            ? const Text('Analizando...')
            : const Text('Identificar enfermedad'),
        style: AppTheme.elevatedButtonStyle(AppTheme.accent),
      );
}
