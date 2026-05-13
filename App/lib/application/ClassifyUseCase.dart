import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class ClassifyUseCase {
  final ImageClassifier _classifier;

  const ClassifyUseCase(this._classifier);

  Future<PredictionResult> execute(XFile image) => _classifier.classify(image);
}

class PredictHealthUseCase extends ClassifyUseCase {
  const PredictHealthUseCase(super.classifier);
}

class PredictDiseaseUseCase extends ClassifyUseCase {
  const PredictDiseaseUseCase(super.classifier);
}
