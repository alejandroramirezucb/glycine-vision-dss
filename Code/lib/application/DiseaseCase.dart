import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class PredictDiseaseUseCase {
  final ImageClassifier _classifier;

  PredictDiseaseUseCase(this._classifier);

  Future<PredictionResult> execute(XFile image) => _classifier.classify(image);
}
