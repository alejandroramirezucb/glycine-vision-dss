import 'package:flutter/material.dart';
import '../../domain/DiseaseFinding.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
import '../Theme.dart';

class DiseaseSummaryBanner extends StatelessWidget {
  final List<DiseaseFinding> findings;

  const DiseaseSummaryBanner({super.key, required this.findings});

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
            '${labelToEs(finding.pathogenClass)} · ${finding.avgSeverityPct.toStringAsFixed(1)}%',
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
