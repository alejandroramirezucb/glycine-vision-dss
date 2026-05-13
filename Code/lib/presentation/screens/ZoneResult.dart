import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:provider/provider.dart';
import '../../domain/Protocols.dart';
import '../LabelNames.dart';
import '../Theme.dart';
import '../state/AppState.dart';
import '../widgets/ImagePreview.dart';
import '../widgets/ZoneOverlay.dart';
import '../widgets/ZoneSummaryCard.dart';
import '../widgets/ClimateInputCard.dart';
import '../widgets/OnsetBadge.dart';
import '../widgets/TreatmentCard.dart';

class ZoneResult extends StatelessWidget {
  const ZoneResult({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, state, _) {
        final analysis = state.zoneAnalysis;
        if (analysis == null) {
          return const Center(child: Text('Sin análisis de zonas'));
        }

        final treatmentRepo = Provider.of<TreatmentRepository>(context, listen: false);
        final treatment = analysis.dominantPathogen == null
            ? null
            : treatmentRepo.getByLabelAndSeverity(
                analysis.dominantPathogen!,
                analysis.worstSeverityLevel ?? 'moderada',
              );

        return Column(children: [
          const SizedBox(height: 12),
          const Text(
            'Análisis por zonas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.accentDark,
            ),
          ),
          const SizedBox(height: 10),
          analysis.zones.isEmpty
              ? ImagePreview(imageFile: state.currentImage)
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.radiusImg),
                    child: ZoneOverlay(
                      analysis: analysis,
                      imageChild: ImagePreview(imageFile: state.currentImage, height: null),
                    ),
                  ),
                ),
          const SizedBox(height: 12),
          if (analysis.isHealthy)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'No se detectaron zonas enfermas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          else
            ZoneSummaryCard(analysis: analysis),
          const SizedBox(height: 12),
          ClimateInputCard(
            climate: state.climate,
            loading: state.climateLoading,
            onFetch: () => _onFetchClimate(context),
            onClear: state.climate == null ? null : () => _onClearClimate(context),
          ),
          if (state.onset != null) ...[
            const SizedBox(height: 12),
            Center(child: OnsetBadge(onset: state.onset!)),
          ],
          if (!analysis.isHealthy && treatment != null) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'Tratamiento basado en ${labelToEs(analysis.dominantPathogen!)} • '
                'nivel ${severityToEs(analysis.worstSeverityLevel ?? 'moderada')}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
              ),
            ),
            const SizedBox(height: 8),
            TreatmentCard(treatment: treatment),
          ],
          const SizedBox(height: 12),
        ]);
      },
    );
  }

  Future<void> _onFetchClimate(BuildContext context) async {
    final state = context.read<AppState>();
    state.setClimateLoading(true);
    try {
      var lat = -17.78;
      var lon = -63.18;
      try {
        final permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.always ||
            permission == LocationPermission.whileInUse) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 8)),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (_) {
        // fallback a Santa Cruz default
      }
      final repo = Provider.of<ClimateRepository>(context, listen: false);
      final data = await repo.fetch(lat, lon);
      if (!context.mounted) return;
      state.setClimate(data);
      _recomputeOnset(context);
    } finally {
      state.setClimateLoading(false);
    }
  }

  void _onClearClimate(BuildContext context) {
    final state = context.read<AppState>();
    state.setClimate(null);
    _recomputeOnset(context);
  }

  void _recomputeOnset(BuildContext context) {
    final state = context.read<AppState>();
    final analysis = state.zoneAnalysis;
    if (analysis == null || analysis.dominantPathogen == null || analysis.worstSeverityLevel == null) {
      state.setOnset(null);
      return;
    }
    final estimator = Provider.of<OnsetEstimator>(context, listen: false);
    state.setOnset(estimator.estimate(
      pathogenClass: analysis.dominantPathogen!,
      severityLevel: analysis.worstSeverityLevel!,
      climate: state.climate,
    ));
  }
}
