import 'package:image_picker/image_picker.dart';
import '../domain/Protocols.dart';
import '../domain/ZoneAnalysis.dart';
import 'Classifier.dart';
import 'SeverityCalculator.dart';

class LocalZoneAnalyzer implements ZoneAnalyzer {
  LocalZoneAnalyzer({
    required TfliteClassifier healthModel,
    required TfliteClassifier diseaseModel,
    SeverityCalculator severity = const SeverityCalculator(),
    int patchSize = 150,
    int stride = 75,
    double diseaseThreshold = 0.5,
    int maxImageSide = 600,
  });

  @override
  Future<ZoneAnalysis> analyze(XFile imageFile, {double? lat, double? lon}) async =>
      throw UnsupportedError('LocalZoneAnalyzer no disponible en web');
}
