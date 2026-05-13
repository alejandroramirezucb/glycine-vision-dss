import 'package:image_picker/image_picker.dart';
import '../domain/Protocols.dart';
import '../domain/ZoneAnalysis.dart';

class LocalZoneAnalyzer implements ZoneAnalyzer {
  LocalZoneAnalyzer({
    required Object healthModel,
    required Object diseaseModel,
    Object? severity,
    int patchSize = 150,
    int stride = 75,
    double diseaseThreshold = 0.5,
    int maxImageSide = 600,
  });

  @override
  Future<ZoneAnalysis> analyze(XFile imageFile, {double? lat, double? lon}) async =>
      throw UnsupportedError('LocalZoneAnalyzer no disponible en web');
}
