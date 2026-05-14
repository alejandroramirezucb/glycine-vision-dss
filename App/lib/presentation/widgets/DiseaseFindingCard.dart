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
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Header(label: labelToEs(finding.pathogenClass), accent: accent),
          const SizedBox(height: 10),
          _SeverityBar(percent: finding.avgSeverityPct, accent: accent),
          const SizedBox(height: 10),
          _MetricsRow(finding: finding),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String label;
  final Color accent;

  const _Header({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 24,
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
    final clamped = percent.clamp(0, 100).toDouble();
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
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: SizedBox(
            height: 8,
            child: LinearProgressIndicator(
              value: clamped / 100,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation(accent),
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
        _Metric(
          label: 'Cobertura',
          value: '${finding.coveragePct.toStringAsFixed(0)}%',
        ),
        _Metric(
          label: 'Nivel',
          value: severityToEs(finding.severityLevel),
        ),
        _Metric(
          label: 'Zonas',
          value: '${finding.zoneCount}',
        ),
        _Metric(
          label: 'Sev. máx',
          value: '${finding.maxSeverityPct.toStringAsFixed(0)}%',
        ),
      ],
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
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }
}
