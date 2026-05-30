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
import '../widgets/SegmentationOverlay.dart';
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
        if (result.hasSegmentation) ...[
          _GlobalSeverityPanel(result: result),
          const SizedBox(height: 10),
        ],
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

class _ImageSection extends StatefulWidget {
  final dynamic image;
  final domain.DiagnoseResult result;

  const _ImageSection({required this.image, required this.result});

  @override
  State<_ImageSection> createState() => _ImageSectionState();
}

class _ImageSectionState extends State<_ImageSection> {
  bool _showSeg = true;

  Widget _buildOverlay(domain.DiagnoseResult result) {
    final preview = ImagePreview(imageFile: widget.image, height: null);
    final aspect = result.imageHeight > 0
        ? result.imageWidth / result.imageHeight
        : 1.0;

    if (result.hasSegmentation && _showSeg) {
      return SegmentationOverlay(
        mask256: result.segMask256!,
        imageChild: preview,
        aspectRatio: aspect,
      );
    }
    if (!result.isHealthy) {
      return ZoneOverlay(result: result, imageChild: preview);
    }
    return preview;
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final overlay = _buildOverlay(result);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.radiusImg),
      child: Stack(
        children: [
          InteractiveViewer(
            minScale: 1.0,
            maxScale: 6.0,
            child: overlay,
          ),
          if (result.hasSegmentation)
            Positioned(
              top: 8,
              right: 8,
              child: _SegToggleChip(
                active: _showSeg,
                onToggle: () => setState(() => _showSeg = !_showSeg),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegToggleChip extends StatelessWidget {
  final bool active;
  final VoidCallback onToggle;

  const _SegToggleChip({required this.active, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? Icons.layers_rounded : Icons.layers_clear_rounded,
              color: Colors.white,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              active ? 'SEG' : 'ZONAS',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlobalSeverityPanel extends StatelessWidget {
  final domain.DiagnoseResult result;

  const _GlobalSeverityPanel({required this.result});

  @override
  Widget build(BuildContext context) {
    final sev = result.globalSeverityPct;
    final clo = result.chlorosisPct;
    final nec = result.necrosisPct;
    final sevColor = AppTheme.severityPctColor(sev);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Severidad foliar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sev.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: sevColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (sev / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(sevColor),
              minHeight: 7,
            ),
          ),
          if (clo > 0 || nec > 0) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (clo > 0) _SymptomTag(
                  label: 'Clorosis',
                  pct: clo,
                  color: const Color(0xFFFDD835),
                ),
                if (clo > 0 && nec > 0) const SizedBox(width: 12),
                if (nec > 0) _SymptomTag(
                  label: 'Necrosis',
                  pct: nec,
                  color: const Color(0xFF795548),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _SymptomTag extends StatelessWidget {
  final String label;
  final double pct;
  final Color color;

  const _SymptomTag({required this.label, required this.pct, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          '$label: ${pct.toStringAsFixed(1)}%',
          style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
      ],
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

  @override
  Widget build(BuildContext context) {
    final accent = pathogenColor(finding.pathogenClass);
    final levelColor = AppTheme.severityLevelColor(finding.severityLevel);
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
