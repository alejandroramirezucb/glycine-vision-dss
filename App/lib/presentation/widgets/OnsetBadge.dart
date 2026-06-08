import 'package:flutter/material.dart';
import '../../domain/OnsetEstimate.dart';
import '../Theme.dart';
import 'GlassCard.dart';

class OnsetBadge extends StatelessWidget {
  final OnsetEstimate onset;

  const OnsetBadge({super.key, required this.onset});

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      radius: AppTheme.radiusChip,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(mainAxisSize: MainAxisSize.max, children: [
        const Icon(Icons.schedule_outlined, size: 16, color: AppTheme.accent),
        const SizedBox(width: 6),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                onset.indicated
                    ? 'Inicio: hace ${onset.minDays} días'
                    : 'Inicio estimado: ${onset.rangeLabel}',
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
