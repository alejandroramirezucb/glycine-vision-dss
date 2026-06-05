import 'dart:typed_data';
import 'package:image/image.dart' as img;

class TfliteSegmenter {
  TfliteSegmenter._();

  static Future<TfliteSegmenter> load({required String modelAsset}) async {
    throw UnsupportedError('TfliteSegmenter no disponible en web');
  }

  Uint8List segment(img.Image source) =>
      throw UnsupportedError('TfliteSegmenter no disponible en web');

  img.Image applyMask(img.Image source, Uint8List mask256) =>
      throw UnsupportedError('TfliteSegmenter no disponible en web');

  double severityPct(Uint8List mask256) =>
      throw UnsupportedError('TfliteSegmenter no disponible en web');

  ({double chlorosis, double necrosis}) decompose(
          img.Image source, Uint8List mask256) =>
      throw UnsupportedError('TfliteSegmenter no disponible en web');
}
