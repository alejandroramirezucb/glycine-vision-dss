import 'package:image_picker/image_picker.dart';
import 'Entities.dart';
import 'Treatment.dart';
import 'ZoneAnalysis.dart';
import 'ClimateData.dart';
import 'OnsetEstimate.dart';

abstract class ImageClassifier {
  Future<PredictionResult> classify(XFile image);
}

abstract class TreatmentRepository {
  TreatmentInfo? getByLabel(String label);
  TreatmentInfo? getByLabelAndSeverity(String label, String severityLevel);
}

abstract class ZoneAnalyzer {
  Future<ZoneAnalysis> analyze(XFile image, {double? lat, double? lon});
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
