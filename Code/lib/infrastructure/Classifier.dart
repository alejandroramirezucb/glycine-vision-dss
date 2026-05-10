import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../domain/Entities.dart';
import '../domain/Protocols.dart';

class TfliteClassifier implements ImageClassifier {
  final Interpreter _interpreter;
  final List<String> _labels;
  final int _inputSize;

  TfliteClassifier._({
    required Interpreter interpreter,
    required List<String> labels,
    required int inputSize,
  })  : _interpreter = interpreter,
        _labels = labels,
        _inputSize = inputSize;

  static Future<TfliteClassifier> load(
    String modelAsset,
    String labelsAsset, {
    int inputSize = 224,
  }) async {
    final interpreter = await Interpreter.fromAsset(modelAsset);
    final labelsText = await rootBundle.loadString(labelsAsset);
    final labels = labelsText
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map(_stripIndex)
        .toList();
    return TfliteClassifier._(
      interpreter: interpreter,
      labels: labels,
      inputSize: inputSize,
    );
  }

  static String _stripIndex(String label) {
    final parts = label.split(' ');
    return (parts.length >= 2 && int.tryParse(parts[0]) != null)
        ? parts.sublist(1).join(' ')
        : label;
  }

  @override
  Future<PredictionResult> classify(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) throw Exception('Imagen inválida');
    final resized =
        img.copyResize(image, width: _inputSize, height: _inputSize);

    final isQuantized =
        _interpreter.getInputTensor(0).type == TensorType.uint8;

    List<double> scores;
    if (isQuantized) {
      final input = [_toUint8Grid(resized)];
      final output = [List<int>.filled(_labels.length, 0)];
      _interpreter.run(input, output);
      scores = output[0].map((v) => v / 255.0).toList();
    } else {
      final input = [_toFloat32Grid(resized)];
      final output = [List<double>.filled(_labels.length, 0.0)];
      _interpreter.run(input, output);
      scores = output[0];
    }

    return PredictionResult(
      predictions: _buildPredictions(scores),
      imagePath: imageFile.path,
    );
  }

  List<List<List<double>>> _toFloat32Grid(img.Image image) =>
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
            final p = image.getPixelSafe(x, y);
            return [
              ((p.r as int) & 0xFF) / 127.5 - 1.0,
              ((p.g as int) & 0xFF) / 127.5 - 1.0,
              ((p.b as int) & 0xFF) / 127.5 - 1.0,
            ];
          }));

  List<List<List<int>>> _toUint8Grid(img.Image image) =>
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
            final p = image.getPixelSafe(x, y);
            return [
              (p.r as int) & 0xFF,
              (p.g as int) & 0xFF,
              (p.b as int) & 0xFF,
            ];
          }));

  List<PredictionItem> _buildPredictions(List<double> probs) {
    final items = [
      for (var i = 0; i < probs.length && i < _labels.length; i++)
        PredictionItem(label: _labels[i], confidence: probs[i])
    ];
    items.sort((a, b) => b.confidence.compareTo(a.confidence));
    return items;
  }
}
