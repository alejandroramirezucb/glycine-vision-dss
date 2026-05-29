import 'dart:typed_data';

import 'package:image/image.dart' as img;

class ChromaticNormalizer {
  static const int _bins = 256;

  final int _tiles;
  final double _clipLimit;

  const ChromaticNormalizer({int tiles = 8, double clipLimit = 2.0})
      : _tiles = tiles,
        _clipLimit = clipLimit;

  img.Image normalize(img.Image source) {
    final balanced = _grayWorld(source);
    return _claheLuminance(balanced);
  }

  img.Image _grayWorld(img.Image src) {
    final bytes = src.getBytes(order: img.ChannelOrder.rgb);
    var sumR = 0.0, sumG = 0.0, sumB = 0.0;
    for (var i = 0; i < bytes.length; i += 3) {
      sumR += bytes[i];
      sumG += bytes[i + 1];
      sumB += bytes[i + 2];
    }
    final count = bytes.length / 3;
    final meanR = sumR / count;
    final meanG = sumG / count;
    final meanB = sumB / count;
    final gray = (meanR + meanG + meanB) / 3.0;
    final scaleR = gray / (meanR + 1e-6);
    final scaleG = gray / (meanG + 1e-6);
    final scaleB = gray / (meanB + 1e-6);

    final out = Uint8List(bytes.length);
    for (var i = 0; i < bytes.length; i += 3) {
      out[i] = _clampByte(bytes[i] * scaleR);
      out[i + 1] = _clampByte(bytes[i + 1] * scaleG);
      out[i + 2] = _clampByte(bytes[i + 2] * scaleB);
    }
    return img.Image.fromBytes(
      width: src.width,
      height: src.height,
      bytes: out.buffer,
      order: img.ChannelOrder.rgb,
    );
  }

  img.Image _claheLuminance(img.Image src) {
    final w = src.width;
    final h = src.height;
    final bytes = src.getBytes(order: img.ChannelOrder.rgb);
    final lum = Uint8List(w * h);
    for (var p = 0, i = 0; p < lum.length; p++, i += 3) {
      lum[p] = _clampByte(
          0.299 * bytes[i] + 0.587 * bytes[i + 1] + 0.114 * bytes[i + 2]);
    }

    final tileW = (w / _tiles).ceil();
    final tileH = (h / _tiles).ceil();
    final maps = List.generate(
      _tiles * _tiles,
      (t) => _tileMap(lum, w, h, (t % _tiles), (t ~/ _tiles), tileW, tileH),
    );

    final out = Uint8List(bytes.length);
    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final p = y * w + x;
        final original = lum[p];
        final mapped = _bilinearMap(maps, x, y, tileW, tileH, original);
        final factor = original == 0 ? 1.0 : mapped / original;
        final i = p * 3;
        out[i] = _clampByte(bytes[i] * factor);
        out[i + 1] = _clampByte(bytes[i + 1] * factor);
        out[i + 2] = _clampByte(bytes[i + 2] * factor);
      }
    }
    return img.Image.fromBytes(
      width: w,
      height: h,
      bytes: out.buffer,
      order: img.ChannelOrder.rgb,
    );
  }

  Uint8List _tileMap(
      Uint8List lum, int w, int h, int tx, int ty, int tileW, int tileH) {
    final x0 = tx * tileW;
    final y0 = ty * tileH;
    final x1 = (x0 + tileW).clamp(0, w);
    final y1 = (y0 + tileH).clamp(0, h);

    final hist = List<int>.filled(_bins, 0);
    var total = 0;
    for (var y = y0; y < y1; y++) {
      final base = y * w;
      for (var x = x0; x < x1; x++) {
        hist[lum[base + x]]++;
        total++;
      }
    }
    if (total == 0) return _identityMap();

    _clipHistogram(hist, total);
    return _cdfMap(hist, total);
  }

  void _clipHistogram(List<int> hist, int total) {
    final limit = (_clipLimit * total / _bins).round().clamp(1, total);
    var excess = 0;
    for (var i = 0; i < _bins; i++) {
      if (hist[i] > limit) {
        excess += hist[i] - limit;
        hist[i] = limit;
      }
    }
    final boost = excess ~/ _bins;
    final remainder = excess % _bins;
    for (var i = 0; i < _bins; i++) {
      hist[i] += boost;
    }
    for (var i = 0; i < remainder; i++) {
      hist[i]++;
    }
  }

  Uint8List _cdfMap(List<int> hist, int total) {
    final map = Uint8List(_bins);
    var cumulative = 0;
    for (var i = 0; i < _bins; i++) {
      cumulative += hist[i];
      map[i] = _clampByte(cumulative * 255.0 / total);
    }
    return map;
  }

  Uint8List _identityMap() {
    final map = Uint8List(_bins);
    for (var i = 0; i < _bins; i++) {
      map[i] = i;
    }
    return map;
  }

  double _bilinearMap(
      List<Uint8List> maps, int x, int y, int tileW, int tileH, int value) {
    final gx = (x - tileW / 2) / tileW;
    final gy = (y - tileH / 2) / tileH;
    final tx0 = gx.floor().clamp(0, _tiles - 1);
    final ty0 = gy.floor().clamp(0, _tiles - 1);
    final tx1 = (tx0 + 1).clamp(0, _tiles - 1);
    final ty1 = (ty0 + 1).clamp(0, _tiles - 1);
    final fx = (gx - tx0).clamp(0.0, 1.0);
    final fy = (gy - ty0).clamp(0.0, 1.0);

    final m00 = maps[ty0 * _tiles + tx0][value].toDouble();
    final m10 = maps[ty0 * _tiles + tx1][value].toDouble();
    final m01 = maps[ty1 * _tiles + tx0][value].toDouble();
    final m11 = maps[ty1 * _tiles + tx1][value].toDouble();

    final top = m00 * (1 - fx) + m10 * fx;
    final bottom = m01 * (1 - fx) + m11 * fx;
    return top * (1 - fy) + bottom * fy;
  }

  int _clampByte(double v) => v < 0 ? 0 : (v > 255 ? 255 : v.round());
}
