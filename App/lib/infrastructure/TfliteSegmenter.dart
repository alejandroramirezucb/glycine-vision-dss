import 'dart:math' as math;
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class TfliteSegmenter {
  static const int _maskSize = 256;
  static const double _scaleLo = 0.6;
  static const double _scaleHi = 1.6;

  final Interpreter _interp;
  final bool _isQuantized;

  TfliteSegmenter._(this._interp, this._isQuantized);

  static Future<TfliteSegmenter> load({required String modelAsset}) async {
    final opts = InterpreterOptions()..threads = 4;
    final interp = await Interpreter.fromAsset(modelAsset, options: opts);
    final isQ = interp.getInputTensor(0).type == TensorType.uint8;
    return TfliteSegmenter._(interp, isQ);
  }

  Uint8List segmentLeaf(img.Image source) {
    final resized = img.copyResize(source, width: _maskSize, height: _maskSize);
    final src = _shadesOfGray(resized.getBytes(order: img.ChannelOrder.rgb));
    final n = _maskSize * _maskSize;
    final channels = _interp.getOutputTensor(0).shape.last;

    if (_isQuantized) {
      _interp.getInputTensor(0).data.buffer.asUint8List().setAll(0, src);
      _interp.invoke();
      final out = _interp.getOutputTensor(0).data.buffer.asUint8List();
      return _largestComponent(_leafArgmax(out, n, channels, (i) => out[i].toDouble()));
    }

    final inputFlat = Float32List(n * 3);
    for (var i = 0; i < src.length; i++) inputFlat[i] = src[i].toDouble();
    _interp.getInputTensor(0).data.buffer.asFloat32List().setAll(0, inputFlat);
    _interp.invoke();
    final out = _interp.getOutputTensor(0).data.buffer.asFloat32List();
    return _largestComponent(_leafArgmax(out, n, channels, (i) => out[i]));
  }

  img.Image normalized256(img.Image source) {
    final resized = img.copyResize(source, width: _maskSize, height: _maskSize);
    final src = _shadesOfGray(resized.getBytes(order: img.ChannelOrder.rgb));
    final out = img.Image(width: _maskSize, height: _maskSize);
    var k = 0;
    for (var y = 0; y < _maskSize; y++) {
      for (var x = 0; x < _maskSize; x++) {
        out.setPixelRgb(x, y, src[k], src[k + 1], src[k + 2]);
        k += 3;
      }
    }
    return out;
  }

  img.Image applyMask(img.Image source, Uint8List leaf256) {
    final w = source.width;
    final h = source.height;
    final out = img.Image(width: w, height: h);
    final scaleX = _maskSize / w;
    final scaleY = _maskSize / h;
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final mx = (x * scaleX).round().clamp(0, _maskSize - 1);
        final my = (y * scaleY).round().clamp(0, _maskSize - 1);
        if (leaf256[my * _maskSize + mx] == 0)
          out.setPixelRgba(x, y, 0, 0, 0, 255);
        else
          out.setPixel(x, y, source.getPixel(x, y));
      }
    }
    return out;
  }

  Uint8List _shadesOfGray(Uint8List rgb) {
    var sr = 0.0, sg = 0.0, sb = 0.0;
    final pixels = rgb.length ~/ 3;
    for (var i = 0; i < rgb.length; i += 3) {
      final r = rgb[i].toDouble(), g = rgb[i + 1].toDouble(), b = rgb[i + 2].toDouble();
      sr += r * r * r * r * r * r;
      sg += g * g * g * g * g * g;
      sb += b * b * b * b * b * b;
    }
    final ir = _pow6root(sr / pixels);
    final ig = _pow6root(sg / pixels);
    final ib = _pow6root(sb / pixels);
    final gray = (ir + ig + ib) / 3;
    final kr = (gray / (ir + 1e-6)).clamp(_scaleLo, _scaleHi);
    final kg = (gray / (ig + 1e-6)).clamp(_scaleLo, _scaleHi);
    final kb = (gray / (ib + 1e-6)).clamp(_scaleLo, _scaleHi);
    final out = Uint8List(rgb.length);
    for (var i = 0; i < rgb.length; i += 3) {
      out[i] = (rgb[i] * kr).clamp(0, 255).toInt();
      out[i + 1] = (rgb[i + 1] * kg).clamp(0, 255).toInt();
      out[i + 2] = (rgb[i + 2] * kb).clamp(0, 255).toInt();
    }
    return out;
  }

  double _pow6root(double v) => v <= 0 ? 0 : math.pow(v, 1.0 / 6.0).toDouble();

  Uint8List _leafArgmax(List flat, int n, int channels, double Function(int) at) {
    final mask = Uint8List(n);
    for (var i = 0; i < n; i++) {
      var best = 0;
      var bestVal = at(i * channels);
      for (var c = 1; c < channels; c++) {
        final v = at(i * channels + c);
        if (v > bestVal) {
          bestVal = v;
          best = c;
        }
      }
      mask[i] = best == 1 ? 1 : 0;
    }
    return mask;
  }

  Uint8List _largestComponent(Uint8List leaf) {
    final labels = Int32List(leaf.length);
    final queue = Int32List(leaf.length);
    var bestSize = 0;
    var bestLabel = 0;
    var current = 0;
    for (var start = 0; start < leaf.length; start++) {
      if (leaf[start] == 0 || labels[start] != 0) continue;
      current++;
      var head = 0, tail = 0, size = 0;
      queue[tail++] = start;
      labels[start] = current;
      while (head < tail) {
        final px = queue[head++];
        size++;
        final x = px % _maskSize;
        for (final d in const [-1, 1, -_maskSize, _maskSize]) {
          final nx = px + d;
          if (d == -1 && x == 0) continue;
          if (d == 1 && x == _maskSize - 1) continue;
          if (nx < 0 || nx >= leaf.length) continue;
          if (leaf[nx] == 1 && labels[nx] == 0) {
            labels[nx] = current;
            queue[tail++] = nx;
          }
        }
      }
      if (size > bestSize) {
        bestSize = size;
        bestLabel = current;
      }
    }
    if (bestLabel == 0) return leaf;
    final threshold = (0.15 * bestSize).round();
    final out = Uint8List(leaf.length);
    final sizes = Int32List(current + 1);
    for (final l in labels) {
      if (l > 0) sizes[l]++;
    }
    for (var i = 0; i < leaf.length; i++) {
      final l = labels[i];
      if (l == bestLabel || (l > 0 && sizes[l] >= threshold)) out[i] = 1;
    }
    return out;
  }
}
