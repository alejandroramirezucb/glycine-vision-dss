import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class PredictHealthUseCase {
  final ImageClassifier _classifier;

  PredictHealthUseCase(this._classifier);

  Future<PredictionResult> execute(XFile image) => _classifier.classify(image);
}
