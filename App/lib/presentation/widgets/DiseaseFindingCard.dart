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
          _Header(
            label: labelToEs(finding.pathogenClass),
            accent: accent,
            severityLevel: finding.severityLevel,
          ),
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
  final String severityLevel;

  const _Header({
    required this.label,
    required this.accent,
    required this.severityLevel,
  });

  static Color _levelBg(String level) {
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
    final badgeColor = _levelBg(severityLevel);
    final isDark = badgeColor == const Color(0xFFFDD835);
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: badgeColor,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            severityToEs(severityLevel).toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.black87 : Colors.white,
              letterSpacing: 0.4,
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
