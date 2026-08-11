import 'package:flutter_test/flutter_test.dart';
import 'package:glycine_vision_dss/infrastructure/quantization.dart';

void main() {
  group('OutputQuantization', () {
    test('aplica (q - zeroPoint) * scale con los parametros reales del tensor', () {
      const quant = OutputQuantization(0.00390625, 0);
      expect(quant(0), 0.0);
      expect(quant(128), closeTo(0.5, 1e-9));
      expect(quant(255), closeTo(0.99609375, 1e-9));
    });

    test('respeta un zeroPoint distinto de cero', () {
      const quant = OutputQuantization(0.5, 10);
      expect(quant(10), 0.0);
      expect(quant(12), closeTo(1.0, 1e-9));
      expect(quant(8), closeTo(-1.0, 1e-9));
    });

    test('difiere de la formula anterior q / 255 en los modelos desplegados', () {
      const quant = OutputQuantization(0.00390625, 0);
      final anterior = 255 / 255.0;
      expect(quant(255), lessThan(anterior));
      expect((anterior - quant(255)).abs(), closeTo(0.00390625, 1e-9));
    });

    test('reproduce los valores de referencia del interprete de TensorFlow Lite', () {
      const quant = OutputQuantization(0.00390625, 0);
      const referencia = <int, double>{
        0: 0.0,
        51: 0.19921875,
        102: 0.3984375,
        153: 0.59765625,
        204: 0.796875,
        255: 0.99609375,
      };
      referencia.forEach((cuantizado, esperado) {
        expect(quant(cuantizado), closeTo(esperado, 1e-9));
      });
    });
  });
}
