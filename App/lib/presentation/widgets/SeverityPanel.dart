import 'package:flutter/material.dart';
import '../../domain/DiagnoseResult.dart';
import '../Theme.dart';

class SeverityPanel extends StatelessWidget {
  final DiagnoseResult result;

  const SeverityPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final sev = result.globalSeverityPct;
    final sevColor = AppTheme.severityPctColor(sev);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Severidad foliar',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                '${sev.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: sevColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (sev / 100).clamp(0.0, 1.0),
              backgroundColor: AppTheme.border,
              valueColor: AlwaysStoppedAnimation<Color>(sevColor),
              minHeight: 7,
            ),
          ),
        ],
      ),
    );
  }
}
