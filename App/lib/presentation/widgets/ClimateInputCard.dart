import 'package:flutter/material.dart';
import '../../domain/ClimateData.dart';
import '../Theme.dart';

class ClimateInputCard extends StatelessWidget {
  final ClimateData? climate;
  final bool loading;
  final VoidCallback onFetch;
  final VoidCallback? onClear;

  const ClimateInputCard({
    super.key,
    required this.climate,
    required this.loading,
    required this.onFetch,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppTheme.cardDecoration(),
      padding: const EdgeInsets.all(14),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Datos climáticos',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppTheme.accentDark,
              ),
            ),
            if (climate != null && onClear != null)
              TextButton(
                onPressed: onClear,
                child: const Text('Quitar', style: TextStyle(fontSize: 11)),
              ),
          ],
        ),
        const SizedBox(height: 6),
        if (climate == null) ...[
          const Text(
            'Opcional: usa tu ubicación para mejorar la estimación de onset.',
            style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: loading ? null : onFetch,
            icon: const Icon(Icons.location_on_outlined, size: 18),
            label: Text(loading ? 'Obteniendo…' : 'Usar mi ubicación'),
            style: AppTheme.elevatedButtonStyle(AppTheme.accent),
          ),
        ] else ...[
          Row(children: [
            _kv('Temp.', '${climate!.tempC.toStringAsFixed(1)} °C'),
            _kv('Humedad', '${climate!.humidity.toStringAsFixed(0)} %'),
            _kv('Lluvia', '${climate!.precipMm.toStringAsFixed(1)} mm'),
          ]),
        ],
      ]),
    );
  }

  Widget _kv(String k, String v) => Expanded(
        child: Column(children: [
          Text(v, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.accentDark)),
          Text(k, style: const TextStyle(fontSize: 10, color: AppTheme.textMuted)),
        ]),
      );
}
