import 'ClimateData.dart';
import 'DiseaseFinding.dart';
import 'OnsetEstimate.dart';
import 'TreatmentPlan.dart';

abstract class TreatmentRepository {
  TreatmentPlan buildComposite({
    required List<DiseaseFinding> findings,
    ClimateData? climate,
    double fieldAreaHa = 1.0,
  });
}

abstract class ClimateRepository {
  Future<ClimateData?> fetch(double lat, double lon);
}

abstract class OnsetEstimator {
  OnsetEstimate estimate({
    required String pathogenClass,
    required String severityLevel,
    ClimateData? climate,
  });
}
