import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class TfliteClassifier implements ImageClassifier {
  final List<String> _labels;
  final int _inputSize;

  TfliteClassifier({required List<String> labels, required int inputSize})
      : _labels = labels,
        _inputSize = inputSize;

  static Future<TfliteClassifier> load(String labelsAsset,
      {int inputSize = 224}) async {
    final labelsText = await rootBundle.loadString(labelsAsset);
    final labels =
        labelsText.split('\n').where((l) => l.trim().isNotEmpty).toList();
    return TfliteClassifier(labels: labels, inputSize: inputSize);
  }

  @override
  Future<PredictionResult> classify(XFile imageFile) async {
    final scores = _mockInference();
    return PredictionResult(
      predictions: _buildPredictions(scores),
      imagePath: imageFile.path,
    );
  }

  List<double> _mockInference() =>
      List<double>.filled(_labels.length, 1.0 / _labels.length);

  List<PredictionItem> _buildPredictions(List<double> probs) {
    final predictions = [
      for (var i = 0; i < probs.length && i < _labels.length; i++)
        PredictionItem(label: _labels[i], confidence: probs[i])
    ];
    predictions.sort((a, b) => b.confidence.compareTo(a.confidence));
    return predictions;
  }
}
