import cv2
import numpy as np
from dataclasses import dataclass


@dataclass
class ResultadoSeveridad:
    porcentaje: float
    nivel: str
    urgencia: str
    mask_lesion: np.ndarray
    pixeles_sanos: int
    pixeles_enfermos: int
    pixeles_fondo: int


RANGO_VERDE_SANO = [
    (np.array([30, 40, 40]), np.array([85, 255, 255]))
]

RANGO_LESION = [
    (np.array([10, 50, 20]), np.array([30, 255, 200])),
    (np.array([0, 50, 20]), np.array([10, 255, 180])),
]

RANGO_NECRO = [
    (np.array([0, 0, 0]), np.array([180, 80, 60]))
]


def calcular_severidad(img_bgr: np.ndarray) -> ResultadoSeveridad:
    hsv = cv2.cvtColor(img_bgr, cv2.COLOR_BGR2HSV)

    mask_sana = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_VERDE_SANO:
        mask_sana = cv2.bitwise_or(mask_sana, cv2.inRange(hsv, low, high))

    mask_lesion = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_LESION:
        mask_lesion = cv2.bitwise_or(mask_lesion, cv2.inRange(hsv, low, high))

    mask_necro = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_NECRO:
        mask_necro = cv2.bitwise_or(mask_necro, cv2.inRange(hsv, low, high))

    mask_enferma = cv2.bitwise_or(mask_lesion, mask_necro)
    kernel = np.ones((3, 3), np.uint8)
    mask_enferma = cv2.morphologyEx(mask_enferma, cv2.MORPH_OPEN, kernel)
    mask_enferma = cv2.morphologyEx(mask_enferma, cv2.MORPH_CLOSE, kernel)

    mask_hoja = cv2.bitwise_or(mask_sana, mask_enferma)

    px_totales = img_bgr.shape[0] * img_bgr.shape[1]
    px_hoja = int(cv2.countNonZero(mask_hoja))
    px_enfermos = int(cv2.countNonZero(mask_enferma))
    px_sanos = int(cv2.countNonZero(mask_sana))
    px_fondo = px_totales - px_hoja

    if px_hoja > (px_totales * 0.1):
        porcentaje = (px_enfermos / px_hoja) * 100
    else:
        porcentaje = 0.0
    porcentaje = min(porcentaje, 100.0)

    if porcentaje < 5:
        nivel, urgencia = "minima", "Solo monitoreo preventivo"
    elif porcentaje < 15:
        nivel, urgencia = "leve", "Aplicacion preventiva recomendada"
    elif porcentaje < 35:
        nivel, urgencia = "moderada", "Tratamiento necesario en 48-72 horas"
    elif porcentaje < 60:
        nivel, urgencia = "severa", "Tratamiento urgente - aplicar hoy"
    else:
        nivel, urgencia = "critica", "Emergencia fitosanitaria - accion inmediata"

    return ResultadoSeveridad(
        porcentaje=round(porcentaje, 1),
        nivel=nivel,
        urgencia=urgencia,
        mask_lesion=mask_enferma,
        pixeles_sanos=px_sanos,
        pixeles_enfermos=px_enfermos,
        pixeles_fondo=px_fondo,
    )


def estimar_severidad_global(img_bgr: np.ndarray, patch_size: int = 150, stride: int = 75) -> dict:
    h, w = img_bgr.shape[:2]
    severidades = []
    for y in range(0, h - patch_size + 1, stride):
        for x in range(0, w - patch_size + 1, stride):
            patch = img_bgr[y:y + patch_size, x:x + patch_size]
            sev = calcular_severidad(patch)
            severidades.append(sev.porcentaje)
    if not severidades:
        return {"mean": 0.0, "max": 0.0, "min": 0.0, "std": 0.0}
    arr = np.array(severidades)
    return {
        "mean": float(arr.mean()),
        "max": float(arr.max()),
        "min": float(arr.min()),
        "std": float(arr.std()),
    }
