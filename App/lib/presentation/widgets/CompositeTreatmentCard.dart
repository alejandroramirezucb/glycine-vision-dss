import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/Treatment.dart';
import '../../domain/TreatmentPlan.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
import '../Theme.dart';

class CompositeTreatmentCard extends StatelessWidget {
  final TreatmentPlan plan;
  final bool climateAvailable;

  const CompositeTreatmentCard({
    super.key,
    required this.plan,
    required this.climateAvailable,
  });

  @override
  Widget build(BuildContext context) {
    if (plan.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Plan de tratamiento',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          if (plan.ventanaAplicacion != null) ...[
            const SizedBox(height: 4),
            Text(
              'Ventana: ${plan.ventanaAplicacion}',
              style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
            ),
          ],
          const SizedBox(height: 12),
          for (var i = 0; i < plan.priorities.length; i++) ...[
            _PriorityBlock(priority: plan.priorities[i], index: i),
            if (i < plan.priorities.length - 1) const SizedBox(height: 12),
          ],
          if (plan.ajusteClimatico != null) ...[
            const Divider(height: 24, color: AppTheme.border),
            _ClimateBlock(text: plan.ajusteClimatico!),
          ],
          if (plan.warnings.isNotEmpty) ...[
            const Divider(height: 24, color: AppTheme.border),
            _WarningsBlock(warnings: plan.warnings),
          ],
          _SourcesBlock(priorities: plan.priorities),
          if (!climateAvailable) ...[
            const SizedBox(height: 10),
            const Text(
              'Sin conexión a internet — para mayor precisión activa GPS y conéctate.',
              style: TextStyle(fontSize: 10, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }
}

class _PriorityBlock extends StatelessWidget {
  static const _labels = ['ACCIÓN INMEDIATA', 'SECUNDARIO', 'COMPLEMENTARIO'];
  static const _icons = [Icons.warning_amber_rounded, Icons.flag_outlined, Icons.spa_outlined];

  final TreatmentPriority priority;
  final int index;

  const _PriorityBlock({required this.priority, required this.index});

  @override
  Widget build(BuildContext context) {
    final accent = pathogenColor(priority.pathogenClass);
    final tag = index < _labels.length ? _labels[index] : 'ADICIONAL';
    final icon = index < _icons.length ? _icons[index] : Icons.circle_outlined;
    return Container(
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: accent),
              const SizedBox(width: 6),
              Text(
                '$tag · ${severityToEs(priority.severityLevel)}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: accent,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            labelToEs(priority.pathogenClass),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          Text(
            priority.rationale,
            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 8),
          _ActionSection(title: 'Químico', text: priority.actions.quimico),
          _ActionSection(title: 'Cultural', text: priority.actions.cultural),
          _ActionSection(title: 'Biológico', text: priority.actions.biologico),
          _ActionSection(title: 'Preventivo', text: priority.actions.preventivo),
        ],
      ),
    );
  }
}

class _ActionSection extends StatelessWidget {
  final String title;
  final String text;

  const _ActionSection({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            text,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ClimateBlock extends StatelessWidget {
  final String text;

  const _ClimateBlock({required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.cloud_outlined, size: 16, color: AppTheme.accent),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ajuste climático',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textPrimary,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _WarningsBlock extends StatelessWidget {
  final List<String> warnings;

  const _WarningsBlock({required this.warnings});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.error_outline, size: 16, color: AppTheme.urgentCrit),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Advertencias de compatibilidad',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.urgentCrit,
                ),
              ),
              const SizedBox(height: 4),
              for (final w in warnings)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '• $w',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textPrimary,
                      height: 1.3,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SourcesBlock extends StatelessWidget {
  final List<TreatmentPriority> priorities;

  const _SourcesBlock({required this.priorities});

  @override
  Widget build(BuildContext context) {
    final sources = _uniqueSources(priorities);
    if (sources.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fuentes',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 4),
          for (final source in sources)
            InkWell(
              onTap: () => launchUrl(
                Uri.parse(source.url),
                mode: LaunchMode.externalApplication,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  '• ${source.texto}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppTheme.accent,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Fuente> _uniqueSources(List<TreatmentPriority> items) {
    final seen = <String>{};
    final out = <Fuente>[];
    for (final p in items) {
      for (final f in p.actions.fuentes) {
        if (seen.add(f.url)) out.add(f);
      }
    }
    return out;
  }
}
