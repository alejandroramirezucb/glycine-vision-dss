import 'package:image_picker/image_picker.dart';
import 'Entities.dart';
import 'Treatment.dart';

abstract class ImageClassifier {
  Future<PredictionResult> classify(XFile image);
}

abstract class TreatmentRepository {
  TreatmentInfo? getByLabel(String label);
}
