import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/DiagnoseResult.dart' as domain;
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/CompositeTreatmentCard.dart';
import '../widgets/DiseaseFindingCard.dart';
import '../widgets/ImagePreview.dart';
import '../widgets/OnsetBadge.dart';
import '../widgets/ZoneOverlay.dart';

class DiagnoseResult extends StatelessWidget {
  const DiagnoseResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final result = state.diagnoseResult;
        if (result == null) {
          return const Center(child: Text('Sin resultado de diagnóstico'));
        }
        return _Layout(image: state.currentImage, result: result);
      },
    );
  }
}

class _Layout extends StatelessWidget {
  final dynamic image;
  final domain.DiagnoseResult result;

  const _Layout({required this.image, required this.result});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 12),
        const _Title(),
        const SizedBox(height: 10),
        _ImageSection(image: image, result: result),
        const SizedBox(height: 12),
        if (result.isHealthy) const _HealthyBanner() else const SizedBox.shrink(),
        if (!result.isHealthy) _ZoneCounter(result: result),
        const SizedBox(height: 12),
        for (final finding in result.findings) ...[
          DiseaseFindingCard(finding: finding),
          const SizedBox(height: 10),
        ],
        if (result.onset != null) ...[
          OnsetBadge(onset: result.onset!),
          const SizedBox(height: 12),
        ],
        if (!result.treatmentPlan.isEmpty) ...[
          CompositeTreatmentCard(
            plan: result.treatmentPlan,
            climateAvailable: result.climate != null,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _Title extends StatelessWidget {
  const _Title();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'Diagnóstico',
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: AppTheme.accentDark,
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  final dynamic image;
  final domain.DiagnoseResult result;

  const _ImageSection({required this.image, required this.result});

  @override
  Widget build(BuildContext context) {
    final preview = ImagePreview(imageFile: image, height: null);
    if (result.isHealthy) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusImg),
        child: preview,
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      child: InteractiveViewer(
        minScale: 1.0,
        maxScale: 6.0,
        child: ZoneOverlay(result: result, imageChild: preview),
      ),
    );
  }
}

class _HealthyBanner extends StatelessWidget {
  const _HealthyBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: const Text(
        'No se detectaron enfermedades. Continuar con monitoreo preventivo.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 13,
          color: Color(0xFF2E7D32),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ZoneCounter extends StatelessWidget {
  final domain.DiagnoseResult result;

  const _ZoneCounter({required this.result});

  @override
  Widget build(BuildContext context) {
    final diseased = result.zones.length;
    final total = result.totalPatches;
    final pct = total == 0 ? 0.0 : diseased / total * 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.crop_free_rounded, size: 18, color: AppTheme.accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$diseased zonas con enfermedad de $total analizadas (${pct.toStringAsFixed(0)}% del follaje)',
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
