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
          _MetricsRow(finding: finding),
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
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
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
                  gradient: LinearGradient(
                    colors: [AppTheme.accentLight, accent],
                  ),
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

class _MetricsRow extends StatelessWidget {
  final DiseaseFinding finding;

  const _MetricsRow({required this.finding});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Metric(label: 'Cobertura', value: '${finding.coveragePct.toStringAsFixed(0)}%'),
        _Divider(),
        _Metric(label: 'Nivel', value: severityToEs(finding.severityLevel)),
        _Divider(),
        _Metric(label: 'Probabilidad', value: '${(finding.avgProbability * 100).toStringAsFixed(0)}%'),
        _Divider(),
        _Metric(label: 'Sev. máx', value: '${finding.maxSeverityPct.toStringAsFixed(0)}%'),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 28,
      child: VerticalDivider(
        width: 1,
        thickness: 1,
        color: AppTheme.border,
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;

  const _Metric({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
