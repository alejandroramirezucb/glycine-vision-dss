import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class TfliteClassifier implements ImageClassifier {
  TfliteClassifier._();

  static Future<TfliteClassifier> load(
    String modelAsset,
    String labelsAsset, {
    int inputSize = 224,
  }) async =>
      throw UnsupportedError('TFLite no disponible en web');

  List<String> get labels => const [];

  List<double> classifyImage(img.Image image) =>
      throw UnsupportedError('TFLite no disponible en web');

  @override
  Future<PredictionResult> classify(XFile imageFile) async =>
      throw UnsupportedError('TFLite no disponible en web');
}
