import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteSegmenter {
  static const int _maskSize = 256;

  final Interpreter _interp;
  final bool _isQuantized;

  TfliteSegmenter._(this._interp, this._isQuantized);

  static Future<TfliteSegmenter> load({required String modelAsset}) async {
    final opts = InterpreterOptions()..threads = 4;
    final interp = await Interpreter.fromAsset(modelAsset, options: opts);
    final isQ = interp.getInputTensor(0).type == TensorType.uint8;
    return TfliteSegmenter._(interp, isQ);
  }

  Uint8List segment(img.Image source) {
    final resized = img.copyResize(source, width: _maskSize, height: _maskSize);
    final src = resized.getBytes(order: img.ChannelOrder.rgb);
    final n = _maskSize * _maskSize;

    if (_isQuantized) {
      _interp.getInputTensor(0).data.buffer.asUint8List().setAll(0, src);
      _interp.invoke();
      final outBuffer = _interp.getOutputTensor(0).data.buffer.asUint8List();
      return _argmaxUint8(outBuffer, n);
    }

    final inputFlat = Float32List(n * 3);
    for (var i = 0; i < src.length; i++) inputFlat[i] = src[i].toDouble();
    _interp.getInputTensor(0).data.buffer.asFloat32List().setAll(0, inputFlat);
    _interp.invoke();
    final outBuffer = _interp.getOutputTensor(0).data.buffer.asFloat32List();
    return _argmax(outBuffer, n);
  }

  img.Image applyMask(img.Image source, Uint8List mask256) {
    final w = source.width;
    final h = source.height;
    final out = img.Image(width: w, height: h);
    final scaleX = _maskSize / w;
    final scaleY = _maskSize / h;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final mx = (x * scaleX).round().clamp(0, _maskSize - 1);
        final my = (y * scaleY).round().clamp(0, _maskSize - 1);
        if (mask256[my * _maskSize + mx] == 0)
          out.setPixelRgba(x, y, 0, 0, 0, 255);
        else
          out.setPixel(x, y, source.getPixel(x, y));
      }
    }
    return out;
  }

  double severityPct(Uint8List mask256) {
    var leaf = 0;
    var diseased = 0;
    for (final c in mask256) {
      if (c > 0) leaf++;
      if (c == 2) diseased++;
    }
    return leaf == 0 ? 0.0 : diseased / leaf * 100.0;
  }

  Uint8List _argmax(Float32List flat, int n) {
    final mask = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final c0 = flat[i * 3];
      final c1 = flat[i * 3 + 1];
      final c2 = flat[i * 3 + 2];
      if (c1 >= c0 && c1 >= c2)
        mask[i] = 1;
      else if (c2 > c0)
        mask[i] = 2;
    }
    return mask;
  }

  Uint8List _argmaxUint8(Uint8List flat, int n) {
    final mask = Uint8List(n);
    for (var i = 0; i < n; i++) {
      final c0 = flat[i * 3];
      final c1 = flat[i * 3 + 1];
      final c2 = flat[i * 3 + 2];
      if (c1 >= c0 && c1 >= c2)
        mask[i] = 1;
      else if (c2 > c0)
        mask[i] = 2;
    }
    return mask;
  }
}
