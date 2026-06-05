import 'package:flutter/material.dart';
import '../../domain/DiseaseFinding.dart';
import '../LabelNames.dart';
import '../PathogenColors.dart';
import '../Theme.dart';

class DiseaseLegend extends StatelessWidget {
  final List<DiseaseFinding> findings;

  const DiseaseLegend({super.key, required this.findings});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.bgCard.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Wrap(
        spacing: 14,
        runSpacing: 6,
        children: [
          _Dot(label: 'Sana', color: const Color(0xFF22C55E)),
          ...findings.map((f) => _Dot(
                label: labelToEs(f.pathogenClass),
                color: pathogenColor(f.pathogenClass),
              )),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  final String label;
  final Color color;

  const _Dot({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
