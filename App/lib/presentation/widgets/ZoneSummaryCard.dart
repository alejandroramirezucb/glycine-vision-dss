import 'package:flutter/material.dart';
import '../../domain/ZoneAnalysis.dart';
import '../LabelNames.dart';
import '../Theme.dart';

class ZoneSummaryCard extends StatelessWidget {
  final ZoneAnalysis analysis;

  const ZoneSummaryCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final dist = analysis.pathogenDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = dist.fold<int>(0, (acc, e) => acc + e.value);

    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Análisis por zonas',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 12),
          _healthBar(),
          const SizedBox(height: 14),
          Row(children: [
            _stat('Zonas', '${analysis.zones.length}/${analysis.totalPatches}'),
            _stat('Severidad prom.', '${analysis.avgSeverityPct.toStringAsFixed(1)}%'),
            _stat('Severidad max.', '${analysis.maxSeverityPct.toStringAsFixed(1)}%'),
          ]),
          if (analysis.dominantPathogen != null) ...[
            const Divider(height: 22, color: AppTheme.border),
            Text(
              'Distribución de patógenos',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.accentDark,
              ),
            ),
            const SizedBox(height: 6),
            for (final e in dist)
              _distRow(e.key, e.value, total),
          ],
          if (analysis.worstSeverityLevel != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Text(
                'Nivel global: ',
                style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
              ),
              Text(
                severityToEs(analysis.worstSeverityLevel!),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _healthBar() {
    final h = analysis.overallHealthyPct.clamp(0, 100).toDouble();
    final d = analysis.overallDiseasedPct.clamp(0, 100).toDouble();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text('Sano ${h.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted))),
        Text('Enfermo ${d.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 11, color: AppTheme.textMuted)),
      ]),
      const SizedBox(height: 4),
      ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          height: 10,
          child: Row(children: [
            Expanded(flex: h.round(), child: Container(color: const Color(0xFF4CAF50))),
            Expanded(flex: d.round() == 0 ? 1 : d.round(), child: Container(color: const Color(0xFFE57373))),
          ]),
        ),
      ),
    ]);
  }

  Widget _stat(String title, String value) => Expanded(
        child: Column(children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.accentDark)),
          Text(title, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ]),
      );

  Widget _distRow(String key, int count, int total) {
    final pct = total == 0 ? 0.0 : (count / total) * 100;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
          width: 120,
          child: Text(labelToEs(key), style: const TextStyle(fontSize: 11, color: AppTheme.textPrimary)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LinearProgressIndicator(
                value: pct / 100,
                backgroundColor: AppTheme.border,
                valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 50,
          child: Text(
            '${pct.toStringAsFixed(0)}% ($count)',
            textAlign: TextAlign.right,
            style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
          ),
        ),
      ]),
    );
  }
}
