import 'dart:convert';
import 'package:flutter/foundation.dart';
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
  int _lastBatchSize = -1;

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
    final options = InterpreterOptions();
    if (!kIsWeb) options.threads = 4;
    final interpreter = await Interpreter.fromAsset(modelAsset, options: options);
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

  List<double> run(img.Image image) => runBatch([image]).first;

  List<List<double>> runBatch(List<img.Image> images) {
    final n = images.length;
    if (n == 0) return const [];

    final isQuantized =
        _interpreter.getInputTensor(0).type == TensorType.uint8;
    if (_lastBatchSize != n) {
      _interpreter.resizeInputTensor(0, [n, _inputSize, _inputSize, 3]);
      _interpreter.allocateTensors();
      _lastBatchSize = n;
    }

    final outSize = _interpreter
        .getOutputTensor(0)
        .shape
        .skip(1)
        .reduce((a, b) => a * b);
    final pixelsPerImage = _inputSize * _inputSize * 3;

    if (isQuantized) {
      final inputFlat = Uint8List(n * pixelsPerImage);
      for (var i = 0; i < n; i++) {
        final resized = img.copyResize(images[i], width: _inputSize, height: _inputSize);
        final bytes = resized.getBytes(order: img.ChannelOrder.rgb);
        inputFlat.setRange(i * pixelsPerImage, (i + 1) * pixelsPerImage, bytes);
      }
      _interpreter.getInputTensor(0).data.buffer
          .asUint8List()
          .setAll(0, inputFlat);
      _interpreter.invoke();
      final outBuffer = _interpreter.getOutputTensor(0).data.buffer.asUint8List();
      return List.generate(n, (i) => _expandBinary(
        List.generate(outSize, (j) => outBuffer[i * outSize + j] / 255.0),
      ));
    }

    final inputFlat = Float32List(n * pixelsPerImage);
    for (var i = 0; i < n; i++) {
      final resized = img.copyResize(images[i], width: _inputSize, height: _inputSize);
      final bytes = resized.getBytes(order: img.ChannelOrder.rgb);
      var off = i * pixelsPerImage;
      for (final b in bytes) {
        inputFlat[off++] = b.toDouble();
      }
    }
    _interpreter.getInputTensor(0).data.buffer
        .asFloat32List()
        .setAll(0, inputFlat);
    _interpreter.invoke();
    final outBuffer = _interpreter.getOutputTensor(0).data.buffer.asFloat32List();
    return List.generate(n, (i) => _expandBinary(
      List.generate(outSize, (j) => outBuffer[i * outSize + j]),
    ));
  }

  List<double> _expandBinary(List<double> scores) {
    if (scores.length == 1 && _labels.length == 2) {
      return [1.0 - scores[0], scores[0]];
    }
    return scores;
  }
}
