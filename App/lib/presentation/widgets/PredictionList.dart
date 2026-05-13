import 'package:flutter/material.dart';
import '../../domain/Entities.dart';
import '../LabelNames.dart';
import '../Theme.dart';

class PredictionList extends StatelessWidget {
  final List<PredictionItem> predictions;

  const PredictionList({super.key, required this.predictions});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < predictions.length; i++)
          _buildItem(predictions[i], isTop: i == 0),
      ],
    );
  }

  Widget _buildItem(PredictionItem p, {required bool isTop}) {
    final pct = (p.confidence * 100).toStringAsFixed(1);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelToEs(p.label),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isTop ? FontWeight.w700 : FontWeight.w500,
                  color: isTop ? AppTheme.textPrimary : AppTheme.textMuted,
                ),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isTop ? AppTheme.accent : AppTheme.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: p.confidence,
              minHeight: 5,
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(
                isTop ? AppTheme.accent : const Color(0xFFB0C4CA),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
