import 'package:image_picker/image_picker.dart';
import '../domain/DiagnoseResult.dart';
import '../domain/Diagnoser.dart';

class LocalDiagnoser implements Diagnoser {
  LocalDiagnoser({
    required Object healthModel,
    required Object diseaseModel,
    required Object treatments,
    required Object climateRepo,
    required Object onsetEstimator,
    Object? segmenter,
  });

  @override
  Future<DiagnoseResult> diagnose(XFile image, {double? lat, double? lon}) =>
      throw UnsupportedError('LocalDiagnoser no disponible en web');
}
