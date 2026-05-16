import 'dart:convert';
import 'dart:typed_data';
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

  List<double> run(img.Image image) => runBatch([image]).first;

  /// Batch inference sampling pixel regions directly from [source] image.
  /// Gets raw bytes once and fills tensors via direct array indexing — fast.
  List<List<double>> runBatchFromSource(
    img.Image source,
    List<({int x, int y})> regions,
    int patchSize,
  ) {
    final n = regions.length;
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

    // Obtain raw RGB bytes ONCE for all patches — avoids per-pixel getPixel overhead
    final srcBytes = source.getBytes(order: img.ChannelOrder.rgb);
    final srcW = source.width;
    final srcH = source.height;
    final xScale = patchSize / _inputSize;
    final yScale = patchSize / _inputSize;

    if (isQuantized) {
      final inputFlat = Uint8List(n * pixelsPerImage);
      for (var i = 0; i < n; i++) {
        _fillUint8FromBytes(srcBytes, srcW, srcH, regions[i].x, regions[i].y,
            xScale, yScale, inputFlat, i * pixelsPerImage);
      }
      final output = List.generate(n, (_) => List<int>.filled(outSize, 0));
      _interpreter.run(inputFlat, output);
      return output
          .map((row) => _expandBinary(row.map((v) => v / 255.0).toList()))
          .toList();
    }

    final inputFlat = Float32List(n * pixelsPerImage);
    for (var i = 0; i < n; i++) {
      _fillFloat32FromBytes(srcBytes, srcW, srcH, regions[i].x, regions[i].y,
          xScale, yScale, inputFlat, i * pixelsPerImage);
    }
    final output = List.generate(n, (_) => List<double>.filled(outSize, 0.0));
    _interpreter.run(inputFlat, output);
    return output.map(_expandBinary).toList();
  }

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
        _fillUint8Buffer(
          img.copyResize(images[i], width: _inputSize, height: _inputSize),
          inputFlat,
          i * pixelsPerImage,
        );
      }
      final output = List.generate(n, (_) => List<int>.filled(outSize, 0));
      _interpreter.run(inputFlat, output);
      return output
          .map((row) => _expandBinary(row.map((v) => v / 255.0).toList()))
          .toList();
    }

    final inputFlat = Float32List(n * pixelsPerImage);
    for (var i = 0; i < n; i++) {
      _fillFloat32Buffer(
        img.copyResize(images[i], width: _inputSize, height: _inputSize),
        inputFlat,
        i * pixelsPerImage,
      );
    }
    final output =
        List.generate(n, (_) => List<double>.filled(outSize, 0.0));
    _interpreter.run(inputFlat, output);
    return output.map(_expandBinary).toList();
  }

  // Direct byte-array fill — no getPixel overhead, ~5-8× faster
  void _fillFloat32FromBytes(
    Uint8List srcBytes,
    int srcW,
    int srcH,
    int srcX,
    int srcY,
    double xScale,
    double yScale,
    Float32List buffer,
    int offset,
  ) {
    for (var dy = 0; dy < _inputSize; dy++) {
      final sy = (srcY + dy * yScale).round().clamp(0, srcH - 1);
      final rowBase = sy * srcW * 3;
      for (var dx = 0; dx < _inputSize; dx++) {
        final sx = (srcX + dx * xScale).round().clamp(0, srcW - 1);
        final px = rowBase + sx * 3;
        buffer[offset++] = srcBytes[px].toDouble();
        buffer[offset++] = srcBytes[px + 1].toDouble();
        buffer[offset++] = srcBytes[px + 2].toDouble();
      }
    }
  }

  void _fillUint8FromBytes(
    Uint8List srcBytes,
    int srcW,
    int srcH,
    int srcX,
    int srcY,
    double xScale,
    double yScale,
    Uint8List buffer,
    int offset,
  ) {
    for (var dy = 0; dy < _inputSize; dy++) {
      final sy = (srcY + dy * yScale).round().clamp(0, srcH - 1);
      final rowBase = sy * srcW * 3;
      for (var dx = 0; dx < _inputSize; dx++) {
        final sx = (srcX + dx * xScale).round().clamp(0, srcW - 1);
        final px = rowBase + sx * 3;
        buffer[offset++] = srcBytes[px];
        buffer[offset++] = srcBytes[px + 1];
        buffer[offset++] = srcBytes[px + 2];
      }
    }
  }

  void _fillFloat32Buffer(img.Image image, Float32List buffer, int offset) {
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final p = image.getPixelSafe(x, y);
        buffer[offset++] = (p.r.toInt() & 0xFF).toDouble();
        buffer[offset++] = (p.g.toInt() & 0xFF).toDouble();
        buffer[offset++] = (p.b.toInt() & 0xFF).toDouble();
      }
    }
  }

  void _fillUint8Buffer(img.Image image, Uint8List buffer, int offset) {
    for (var y = 0; y < _inputSize; y++) {
      for (var x = 0; x < _inputSize; x++) {
        final p = image.getPixelSafe(x, y);
        buffer[offset++] = p.r.toInt() & 0xFF;
        buffer[offset++] = p.g.toInt() & 0xFF;
        buffer[offset++] = p.b.toInt() & 0xFF;
      }
    }
  }

  List<double> _expandBinary(List<double> scores) {
    if (scores.length == 1 && _labels.length == 2) {
      return [1.0 - scores[0], scores[0]];
    }
    return scores;
  }
}
