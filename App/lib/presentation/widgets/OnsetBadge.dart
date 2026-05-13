import 'package:flutter/material.dart';
import '../../domain/OnsetEstimate.dart';
import '../Theme.dart';

class OnsetBadge extends StatelessWidget {
  final OnsetEstimate onset;

  const OnsetBadge({super.key, required this.onset});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.schedule_outlined, size: 16, color: AppTheme.accent),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Inicio estimado: ${onset.rangeLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentDark,
                ),
              ),
              if (onset.explanation.isNotEmpty)
                Text(
                  onset.explanation,
                  style: const TextStyle(fontSize: 10, color: AppTheme.textMuted),
                ),
            ],
          ),
        ),
      ]),
    );
  }
}
