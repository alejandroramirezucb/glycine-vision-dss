import 'ClimateData.dart';
import 'DiseaseFinding.dart';
import 'OnsetEstimate.dart';
import 'TreatmentPlan.dart';
import 'Zone.dart';

class DiagnoseResult {
  final List<Zone> zones;
  final List<DiseaseFinding> findings;
  final int imageWidth;
  final int imageHeight;
  final int patchSize;
  final int totalPatches;
  final ClimateData? climate;
  final OnsetEstimate? onset;
  final TreatmentPlan treatmentPlan;

  const DiagnoseResult({
    required this.zones,
    required this.findings,
    required this.imageWidth,
    required this.imageHeight,
    required this.patchSize,
    required this.totalPatches,
    required this.climate,
    required this.onset,
    required this.treatmentPlan,
  });

  bool get isHealthy => zones.isEmpty;
  bool get hasMultipleDiseases => findings.length > 1;
}
