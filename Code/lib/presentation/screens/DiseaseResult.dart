import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/Protocols.dart';
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
        if (result == null) return const Center(child: Text('No result'));

        final treatmentRepo =
            Provider.of<TreatmentRepository>(context, listen: false);
        final treatment =
            treatmentRepo.getByLabel(result.topPrediction.label);

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
              if (treatment != null)
                TreatmentCard(treatment: treatment)
              else
                const Text(
                  'Información de tratamiento no disponible.',
                  style: TextStyle(fontSize: 13),
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }
}
