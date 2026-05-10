import 'package:flutter/material.dart';
import '../../domain/Entities.dart';
import '../Theme.dart';

class PredictionList extends StatelessWidget {
  final List<PredictionItem> predictions;

  const PredictionList({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: predictions.map((p) {
        final percentage = (p.confidence * 100).toStringAsFixed(1);
        return Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  p.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: p.confidence,
                minHeight: 6,
                backgroundColor: AppTheme.border,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.accent),
              ),
            ),
            const SizedBox(height: 12),
          ],
        );
      }).toList(),
    );
  }
}
