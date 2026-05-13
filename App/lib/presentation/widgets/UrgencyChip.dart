import 'package:flutter/material.dart';
import '../Theme.dart';

class UrgencyChip extends StatelessWidget {
  final String urgencia;

  const UrgencyChip({super.key, required this.urgencia});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _getUrgencyStyle(urgencia);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        'Urgencia: $label',
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  (String, Color) _getUrgencyStyle(String urgencia) => switch (
        urgencia.toLowerCase()) {
        'crítica' || 'critica' => ('CRITICA', AppTheme.urgentCrit),
        'alta' => ('ALTA', AppTheme.urgentHigh),
        _ => ('MEDIA', AppTheme.urgentMed),
      };
}
