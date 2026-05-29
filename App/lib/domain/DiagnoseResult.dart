import 'dart:typed_data';

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
  final int leafPatches;
  final ClimateData? climate;
  final OnsetEstimate? onset;
  final TreatmentPlan treatmentPlan;
  final Uint8List? segMask256;
  final double globalSeverityPct;
  final double chlorosisPct;
  final double necrosisPct;

  const DiagnoseResult({
    required this.zones,
    required this.findings,
    required this.imageWidth,
    required this.imageHeight,
    required this.patchSize,
    required this.totalPatches,
    required this.leafPatches,
    required this.climate,
    required this.onset,
    required this.treatmentPlan,
    this.segMask256,
    this.globalSeverityPct = 0.0,
    this.chlorosisPct = 0.0,
    this.necrosisPct = 0.0,
  });

  bool get isHealthy => zones.isEmpty;
  bool get hasSegmentation => segMask256 != null;
  bool get hasMultipleDiseases => findings.length > 1;
}
