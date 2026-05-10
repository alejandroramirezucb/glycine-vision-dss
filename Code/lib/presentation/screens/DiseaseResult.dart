import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/Protocols.dart';
import '../LabelNames.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/ImagePreview.dart';
import '../widgets/PredictionList.dart';
import '../widgets/TreatmentCard.dart';

class DiseaseResult extends StatelessWidget {
  const DiseaseResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.diseaseResult;
        if (result == null) return const Center(child: Text('Sin resultado'));

        final treatmentRepo =
            Provider.of<TreatmentRepository>(context, listen: false);
        final treatment = treatmentRepo.getByLabel(result.topPrediction.label);

        return SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 12),
              const Text(
                'Tipo de enfermedad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.accentDark,
                ),
              ),
              const SizedBox(height: 12),
              ImagePreview(imageFile: state.currentImage),
              const SizedBox(height: 16),
              _buildTopResult(
                  result.topPrediction.label, result.topPrediction.confidence),
              const SizedBox(height: 16),
              PredictionList(predictions: result.predictions),
              const SizedBox(height: 4),
              if (treatment != null)
                TreatmentCard(treatment: treatment)
              else
                const Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                    'Información de tratamiento no disponible.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
                  ),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopResult(String label, double confidence) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.urgentHigh.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.biotech, color: AppTheme.urgentHigh, size: 20),
            const SizedBox(width: 8),
            Text(
              '${labelToEs(label)}  •  ${(confidence * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppTheme.urgentHigh,
              ),
            ),
          ],
        ),
      );
}
