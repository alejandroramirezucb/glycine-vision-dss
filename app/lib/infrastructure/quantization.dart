import 'package:tflite_flutter/tflite_flutter.dart';

class OutputQuantization {
  static const double _fallbackScale = 1.0 / 256.0;
  static const int _fallbackZeroPoint = 0;

  final double scale;
  final int zeroPoint;

  const OutputQuantization(this.scale, this.zeroPoint);

  factory OutputQuantization.of(Tensor tensor) {
    try {
      final params = tensor.params;
      if (params.scale > 0) {
        return OutputQuantization(params.scale, params.zeroPoint);
      }
    } catch (_) {}
    return const OutputQuantization(_fallbackScale, _fallbackZeroPoint);
  }

  double call(int quantized) => (quantized - zeroPoint) * scale;
}
