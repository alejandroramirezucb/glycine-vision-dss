import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/CompositeTreatmentCard.dart';
import '../widgets/OnsetBadge.dart';

class TreatmentScreen extends StatelessWidget {
  const TreatmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.diagnoseResult;
        if (result == null) {
          return const Center(child: Text('Sin resultado de diagnóstico'));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const _Title(),
            const SizedBox(height: 12),
            if (result.onset != null) ...[
              OnsetBadge(onset: result.onset!),
              const SizedBox(height: 10),
            ],
            if (!result.treatmentPlan.isEmpty)
              CompositeTreatmentCard(
                plan: result.treatmentPlan,
                climateAvailable: result.climate != null,
              )
            else
              const _Empty(),
            const SizedBox(height: 12),
          ],
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Tratamiento',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentDark,
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: const Text(
        'No hay tratamiento disponible para este diagnóstico.',
        style: TextStyle(fontSize: 13, color: AppTheme.textMuted),
      ),
    );
  }
}
