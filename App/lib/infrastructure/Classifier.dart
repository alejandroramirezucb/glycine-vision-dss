import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteClassifier {
  static const int _defaultInputSize = 224;
  static const double _defaultThreshold = 0.5;

  final Interpreter _interpreter;
  final List<String> _labels;
  final Map<String, double> _thresholds;
  final int _inputSize;

  TfliteClassifier._({
    required Interpreter interpreter,
    required List<String> labels,
    required Map<String, double> thresholds,
    required int inputSize,
  })  : _interpreter = interpreter,
        _labels = labels,
        _thresholds = thresholds,
        _inputSize = inputSize;

  static Future<TfliteClassifier> load({
    required String modelAsset,
    required String labelsAsset,
    String? thresholdsAsset,
    int inputSize = _defaultInputSize,
  }) async {
    final interpreter = await Interpreter.fromAsset(modelAsset);
    final labels = await _loadLabels(labelsAsset);
    final thresholds = thresholdsAsset == null
        ? <String, double>{}
        : await _loadThresholds(thresholdsAsset, labels);
    return TfliteClassifier._(
      interpreter: interpreter,
      labels: labels,
      thresholds: thresholds,
      inputSize: inputSize,
    );
  }

  static Future<List<String>> _loadLabels(String asset) async {
    final text = await rootBundle.loadString(asset);
    return text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .map(_stripIndex)
        .toList();
  }

  static Future<Map<String, double>> _loadThresholds(
    String asset,
    List<String> labels,
  ) async {
    try {
      final text = await rootBundle.loadString(asset);
      final json = jsonDecode(text) as Map<String, dynamic>;
      return json.map((k, v) => MapEntry(k, (v as num).toDouble()));
    } catch (_) {
      return {for (final l in labels) l: _defaultThreshold};
    }
  }

  static String _stripIndex(String label) {
    final parts = label.split(' ');
    return parts.length >= 2 && int.tryParse(parts[0]) != null
        ? parts.sublist(1).join(' ')
        : label;
  }

  List<String> get labels => List.unmodifiable(_labels);

  double thresholdFor(String label) =>
      _thresholds[label] ?? _defaultThreshold;

  List<double> run(img.Image image) {
    final resized = img.copyResize(image, width: _inputSize, height: _inputSize);
    final outTensor = _interpreter.getOutputTensor(0);
    final outSize = outTensor.shape.reduce((a, b) => a * b);
    final isQuantized =
        _interpreter.getInputTensor(0).type == TensorType.uint8;

    if (isQuantized) {
      final input = [_toUint8Grid(resized)];
      final output = [List<int>.filled(outSize, 0)];
      _interpreter.run(input, output);
      return _expandBinary(output[0].map((v) => v / 255.0).toList());
    }
    final input = [_toFloat32Grid(resized)];
    final output = [List<double>.filled(outSize, 0.0)];
    _interpreter.run(input, output);
    return _expandBinary(output[0]);
  }

  List<double> _expandBinary(List<double> scores) {
    if (scores.length == 1 && _labels.length == 2) {
      return [1.0 - scores[0], scores[0]];
    }
    return scores;
  }

  List<List<List<double>>> _toFloat32Grid(img.Image image) =>
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
            final p = image.getPixelSafe(x, y);
            return [
              (p.r.toInt() & 0xFF) / 127.5 - 1.0,
              (p.g.toInt() & 0xFF) / 127.5 - 1.0,
              (p.b.toInt() & 0xFF) / 127.5 - 1.0,
            ];
          }));

  List<List<List<int>>> _toUint8Grid(img.Image image) =>
      List.generate(_inputSize, (y) => List.generate(_inputSize, (x) {
            final p = image.getPixelSafe(x, y);
            return [
              p.r.toInt() & 0xFF,
              p.g.toInt() & 0xFF,
              p.b.toInt() & 0xFF,
            ];
          }));
}
