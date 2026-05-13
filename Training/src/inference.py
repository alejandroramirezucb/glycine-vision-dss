import cv2
import json
import numpy as np
from collections import Counter
from pathlib import Path
from typing import Optional

import tensorflow as tf

from .severity import calcular_severidad
from .treatments_matrix import obtener_tratamiento
from .climate import fetch_climate, riesgo_por_clima
from .onset import estimar_onset


COLORES = {
    "sana":            (50, 200, 50),
    "bacterianas":     (0, 120, 255),
    "fungicas":        (255, 80, 80),
    "roya":            (0, 0, 200),
    "virales":         (200, 0, 200),
    "plagas_insectos": (0, 200, 200),
}

GROSOR_POR_NIVEL = {
    "minima": 1, "leve": 2, "moderada": 3, "severa": 4, "critica": 5,
}


class GlycineVisionInferencia:
    def __init__(self, ruta_modelo1: str, ruta_modelo2: str, ruta_clases_json: str):
        self.model1 = tf.keras.models.load_model(ruta_modelo1)
        self.model2 = tf.keras.models.load_model(ruta_modelo2)
        with open(ruta_clases_json) as f:
            indices = json.load(f)
        self.idx_a_clase = {v: k for k, v in indices.items()}

    def _preprocesar_patch(self, patch: np.ndarray) -> np.ndarray:
        patch_rgb = cv2.cvtColor(patch, cv2.COLOR_BGR2RGB)
        patch_224 = cv2.resize(patch_rgb, (224, 224))
        return np.expand_dims(patch_224 / 255.0, axis=0).astype(np.float32)

    def _predecir_m1(self, patch_inp: np.ndarray) -> float:
        return float(self.model1.predict(patch_inp, verbose=0)[0][0])

    def _predecir_m2(self, patch_inp: np.ndarray) -> tuple:
        probs = self.model2.predict(patch_inp, verbose=0)[0]
        idx = int(np.argmax(probs))
        return self.idx_a_clase[idx], float(probs[idx]), {self.idx_a_clase[i]: float(p) for i, p in enumerate(probs)}

    def analizar(self, ruta_imagen: str, patch_size: int = 150, stride: int = 75,
                 umbral_enfermedad: float = 0.5,
                 lat: Optional[float] = None, lon: Optional[float] = None) -> dict:
        img = cv2.imread(ruta_imagen)
        if img is None:
            raise ValueError(f"No se pudo leer: {ruta_imagen}")

        resultado_img = img.copy()
        h, w = img.shape[:2]
        zonas = []

        for y in range(0, h - patch_size + 1, stride):
            for x in range(0, w - patch_size + 1, stride):
                patch = img[y:y + patch_size, x:x + patch_size]
                patch_inp = self._preprocesar_patch(patch)
                prob_enf = self._predecir_m1(patch_inp)

                if prob_enf < umbral_enfermedad:
                    cv2.rectangle(resultado_img, (x, y), (x + patch_size, y + patch_size),
                                  COLORES["sana"], 1)
                    continue

                clase, conf, distribucion = self._predecir_m2(patch_inp)
                sev = calcular_severidad(patch)

                color = COLORES.get(clase, (128, 128, 128))
                grosor = GROSOR_POR_NIVEL.get(sev.nivel, 2)
                cv2.rectangle(resultado_img, (x, y), (x + patch_size, y + patch_size),
                              color, grosor)
                label = f"{clase} {sev.porcentaje}% ({sev.nivel})"
                cv2.putText(resultado_img, label, (x + 3, y + 14),
                            cv2.FONT_HERSHEY_SIMPLEX, 0.38, color, 1, cv2.LINE_AA)

                zonas.append({
                    "bbox": [int(x), int(y), int(x + patch_size), int(y + patch_size)],
                    "patogeno": clase,
                    "confianza": round(conf, 3),
                    "distribucion": {k: round(v, 3) for k, v in distribucion.items()},
                    "severidad_pct": sev.porcentaje,
                    "nivel": sev.nivel,
                    "urgencia": sev.urgencia,
                })

        clima = None
        if lat is not None and lon is not None:
            clima = fetch_climate(lat, lon)

        overall = self._resumir(zonas, h, w, patch_size, stride)

        onset = None
        if overall["estado"] == "ENFERMA":
            onset = estimar_onset(overall["clase_dominante"], overall["nivel_global"], clima)

        riesgo = {c: riesgo_por_clima(c, clima) for c in COLORES.keys() if c != "sana"} if clima else None
        trat = None
        if overall["estado"] == "ENFERMA":
            trat = obtener_tratamiento(overall["clase_dominante"], overall["nivel_global"])

        return {
            "imagen_anotada": resultado_img,
            "zonas": zonas,
            "overall": overall,
            "clima": clima,
            "riesgo_por_clase": riesgo,
            "onset": onset,
            "tratamiento": trat,
        }

    def _resumir(self, zonas: list, h: int, w: int, patch_size: int, stride: int) -> dict:
        total_patches = ((h - patch_size) // stride + 1) * ((w - patch_size) // stride + 1)
        if not zonas:
            return {
                "estado": "SANA",
                "zonas_enfermas": 0,
                "total_patches": int(total_patches),
                "porcentaje_enfermo": 0.0,
                "porcentaje_sano": 100.0,
                "clase_dominante": None,
                "distribucion_clases": {},
                "severidad_promedio": 0.0,
                "severidad_maxima": 0.0,
                "nivel_global": None,
            }

        conteo = Counter(z["patogeno"] for z in zonas)
        clase_dom = conteo.most_common(1)[0][0]
        sevs = [z["severidad_pct"] for z in zonas]
        orden = ["minima", "leve", "moderada", "severa", "critica"]
        nivel_global = max((z["nivel"] for z in zonas), key=lambda n: orden.index(n))
        porc_enfermo = (len(zonas) / total_patches) * 100 if total_patches > 0 else 0.0

        return {
            "estado": "ENFERMA",
            "zonas_enfermas": len(zonas),
            "total_patches": int(total_patches),
            "porcentaje_enfermo": round(porc_enfermo, 1),
            "porcentaje_sano": round(100 - porc_enfermo, 1),
            "clase_dominante": clase_dom,
            "distribucion_clases": dict(conteo),
            "severidad_promedio": round(float(np.mean(sevs)), 1),
            "severidad_maxima": round(float(max(sevs)), 1),
            "nivel_global": nivel_global,
        }
