import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../domain/DiagnoseResult.dart' as domain;
import '../../domain/DiseaseFinding.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
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
        if (!result.isHealthy) ...[
          _ZoneCounter(result: result),
          const SizedBox(height: 10),
          _DiseaseSummaryBanner(findings: result.findings),
        ],
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
    final leaf = result.leafPatches;
    final pct = leaf == 0 ? 0.0 : diseased / leaf * 100;
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
              '$diseased zonas enfermas de $leaf zonas de follaje (${pct.toStringAsFixed(0)}% del follaje)',
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

class _DiseaseSummaryBanner extends StatelessWidget {
  final List<DiseaseFinding> findings;

  const _DiseaseSummaryBanner({required this.findings});

  @override
  Widget build(BuildContext context) {
    if (findings.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 8,
        children: findings.map((f) => _DiseaseChip(finding: f)).toList(),
      ),
    );
  }
}

class _DiseaseChip extends StatelessWidget {
  final DiseaseFinding finding;

  const _DiseaseChip({required this.finding});

  static Color _levelColor(String level) {
    switch (level.toLowerCase()) {
      case 'critica':
        return const Color(0xFFB71C1C);
      case 'severa':
        return const Color(0xFFE53935);
      case 'moderada':
        return const Color(0xFFFB8C00);
      case 'leve':
        return const Color(0xFFFDD835);
      default:
        return const Color(0xFF43A047);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = pathogenColor(finding.pathogenClass);
    final levelColor = _levelColor(finding.severityLevel);
    final shortName = labelToEs(finding.pathogenClass)
        .split(' ')
        .first
        .toLowerCase()
        .substring(0, 3);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: levelColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            '$shortName=${finding.avgSeverityPct.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            severityToEs(finding.severityLevel),
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
