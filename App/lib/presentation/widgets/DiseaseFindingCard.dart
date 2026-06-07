import 'package:flutter/material.dart';
import '../../domain/DiseaseFinding.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
import '../Theme.dart';

class DiseaseFindingCard extends StatelessWidget {
  final DiseaseFinding finding;

  const DiseaseFindingCard({super.key, required this.finding});

  @override
  Widget build(BuildContext context) {
    final accent = pathogenColor(finding.pathogenClass);
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(
            label: labelToEs(finding.pathogenClass),
            accent: accent,
            severityLevel: finding.severityLevel,
          ),
          const SizedBox(height: 12),
          _SeverityBar(percent: finding.avgSeverityPct, accent: accent),
          const SizedBox(height: 12),
          _Confidence(probability: finding.avgProbability, accent: accent),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  final Color accent;
  final String severityLevel;

  const _Header({
    required this.label,
    required this.accent,
    required this.severityLevel,
  });

  @override
  Widget build(BuildContext context) {
    final badgeColor = AppTheme.severityLevelColor(severityLevel);
    final isLightBadge = severityLevel.toLowerCase() == 'leve';
    return Row(
      children: [
        Container(
          width: 4,
          height: 22,
          decoration: BoxDecoration(
            color: accent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: accent,
              letterSpacing: -0.2,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
          ),
          child: Text(
            severityToEs(severityLevel).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isLightBadge ? Colors.black87 : Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
    );
  }
}

class _SeverityBar extends StatelessWidget {
  final double percent;
  final Color accent;

  const _SeverityBar({required this.percent, required this.accent});

  @override
  Widget build(BuildContext context) {
    final clamped = percent.clamp(0.0, 100.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Severidad promedio',
              style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
            const Spacer(),
            Text(
              '${clamped.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Container(
            height: 8,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(4),
            ),
            child: FractionallySizedBox(
              widthFactor: clamped / 100,
              alignment: Alignment.centerLeft,
              child: Container(
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Confidence extends StatelessWidget {
  final double probability;
  final Color accent;

  const _Confidence({required this.probability, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.verified_outlined, size: 14, color: accent),
        const SizedBox(width: 6),
        const Text(
          'Confianza del modelo',
          style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
        ),
        const Spacer(),
        Text(
          '${(probability * 100).toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: accent,
          ),
        ),
      ],
    );
  }
}
