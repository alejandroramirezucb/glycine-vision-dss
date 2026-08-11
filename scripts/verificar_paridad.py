"""Verifica que la des-cuantizacion del backend reproduce la del interprete TFLite.

Compara, sobre entradas deterministas, las probabilidades que devuelve
backend/inference frente al calculo de referencia (q - zero_point) * scale
leido de los parametros reales del tensor, y frente a la formula q / 255
que se usaba antes. Sirve de evidencia para la observacion 3 del informe.
"""

import sys
from pathlib import Path

import numpy as np
import tensorflow as tf

RAIZ = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(RAIZ / "backend"))

from inference.quantization import dequantize  # noqa: E402

MODELOS = {
    "M1 estado sanitario (int8)": RAIZ / "app/assets/models/hs/model.tflite",
    "M2 agente causal (float32)": RAIZ / "app/assets/models/pd/model_unquant.tflite",
    "M_seg segmentador (int8)": RAIZ / "app/assets/models/seg/model_seg.tflite",
}
TOLERANCIA = 1e-6


def entradas(interprete, semilla=42):
    generador = np.random.default_rng(semilla)
    valores = {}
    for detalle in interprete.get_input_details():
        alto, ancho = detalle["shape"][1], detalle["shape"][2]
        pixeles = generador.integers(0, 256, size=(1, alto, ancho, 3))
        valores[detalle["index"]] = pixeles.astype(detalle["dtype"])
    return valores


def evaluar(ruta):
    interprete = tf.lite.Interpreter(model_path=str(ruta))
    interprete.allocate_tensors()
    for indice, tensor in entradas(interprete).items():
        interprete.set_tensor(indice, tensor)
    interprete.invoke()

    detalle = interprete.get_output_details()[0]
    crudo = interprete.get_tensor(detalle["index"])[0]
    escala, cero = detalle["quantization"]
    cuantizado = np.dtype(detalle["dtype"]).name in ("uint8", "int8")

    obtenido = dequantize(crudo, detalle)
    referencia = (crudo.astype(np.float32) - cero) * escala if cuantizado else crudo.astype(np.float32)
    anterior = crudo.astype(np.float32) / 255.0 if cuantizado else referencia
    return escala, cero, cuantizado, obtenido, referencia, anterior


def main():
    fallos = 0
    for nombre, ruta in MODELOS.items():
        if not ruta.exists():
            print(f"OMITIDO  {nombre}: no existe {ruta}")
            continue
        escala, cero, cuantizado, obtenido, referencia, anterior = evaluar(ruta)
        desvio = float(np.max(np.abs(obtenido - referencia)))
        deriva = float(np.max(np.abs(referencia - anterior)))
        estado = "OK" if desvio <= TOLERANCIA else "FALLO"
        if desvio > TOLERANCIA:
            fallos += 1
        print(f"{estado:8s} {nombre}")
        print(f"         scale={escala!r}  zero_point={cero!r}  cuantizado={cuantizado}")
        print(f"         desvio backend vs referencia : {desvio:.3e}")
        print(f"         deriva de la formula anterior: {deriva:.3e}")
    if fallos:
        print(f"\n{fallos} modelo(s) fuera de tolerancia.")
        return 1
    print("\nEl backend reproduce exactamente la des-cuantizacion de referencia.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
