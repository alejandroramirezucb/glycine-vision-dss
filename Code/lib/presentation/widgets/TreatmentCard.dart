import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/Treatment.dart';
import '../Theme.dart';
import 'UrgencyChip.dart';

class TreatmentCard extends StatelessWidget {
  final TreatmentInfo treatment;

  const TreatmentCard({super.key, required this.treatment});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Text(
            treatment.nombreEs,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 12),
          UrgencyChip(urgencia: treatment.urgencia),
          const SizedBox(height: 12),
          _buildSection('Patógenos', treatment.patogenos),
          const Divider(height: 24, color: AppTheme.border),
          _buildSection('Síntomas', treatment.sintomas),
          const Divider(height: 24, color: AppTheme.border),
          _buildSection('Tratamiento Químico', treatment.quimico),
          const SizedBox(height: 12),
          _buildSection('Tratamiento Cultural', treatment.cultural),
          const SizedBox(height: 12),
          _buildSection('Control Biológico', treatment.biologico),
          const SizedBox(height: 12),
          _buildSection('Prevención', treatment.preventivo),
          const Divider(height: 24, color: AppTheme.border),
          const Text(
            'Fuentes:',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AppTheme.textMuted,
            ),
          ),
          const SizedBox(height: 8),
          ...treatment.fuentes.map(_buildFuenteLink),
        ],
      ),
    );
  }

  Widget _buildSection(String title, String content) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 4),
          SelectableText(
            content,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textPrimary,
              height: 1.5,
            ),
          ),
        ],
      );

  Widget _buildFuenteLink(Fuente fuente) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Center(
          child: InkWell(
            onTap: () => launchUrl(
              Uri.parse(fuente.url),
              mode: LaunchMode.externalApplication,
            ),
            child: Text(
              '• ${fuente.texto}',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10,
                color: AppTheme.accent,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      );
}
