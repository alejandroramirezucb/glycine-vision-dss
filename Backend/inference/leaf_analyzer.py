import cv2
import numpy as np

_MASK_SIZE = 256
_GREEN_A_MAX = 123
_CHLOROSIS_B_MIN = 150
_CHLOROSIS_L_MIN = 110
_NECROSIS_L_MAX = 130
_NECROSIS_B_MIN = 130
_SOIL_AB_TOL = 14
_SOIL_L_MIN = 150


def _enclosed_holes(leaf: np.ndarray) -> np.ndarray:
    padded = np.pad(leaf.astype(np.uint8), 1, constant_values=0)
    flood = padded.copy()
    cv2.floodFill(flood, np.zeros((padded.shape[0] + 2, padded.shape[1] + 2), np.uint8), (0, 0), 1)
    return (flood[1:-1, 1:-1] == 0) & ~leaf


def analyze_leaf(image_rgb_256: np.ndarray, leaf_mask_256: np.ndarray) -> tuple[np.ndarray, float, dict]:
    lab = cv2.cvtColor(image_rgb_256, cv2.COLOR_RGB2LAB)
    L = lab[:, :, 0].astype(np.int16)
    a = lab[:, :, 1].astype(np.int16)
    b = lab[:, :, 2].astype(np.int16)
    leaf = leaf_mask_256.astype(bool)

    green = a < _GREEN_A_MAX
    chlorosis = leaf & (~green) & (b > _CHLOROSIS_B_MIN) & (L > _CHLOROSIS_L_MIN)
    necrosis = leaf & (~green) & (L < _NECROSIS_L_MAX) & (b > _NECROSIS_B_MIN)

    bg_like = (np.abs(a - 128) < _SOIL_AB_TOL) & (np.abs(b - 128) < _SOIL_AB_TOL + 6) & (L > _SOIL_L_MIN)
    holes = _enclosed_holes(leaf) & bg_like

    expected_area = int(np.count_nonzero(leaf)) + int(np.count_nonzero(holes)) or 1
    symptomatic = chlorosis | necrosis | holes
    severity = round(float(np.count_nonzero(symptomatic)) / expected_area * 100, 1)

    mask3 = np.zeros((_MASK_SIZE, _MASK_SIZE), dtype=np.uint8)
    mask3[leaf] = 1
    mask3[symptomatic] = 2

    components = {
        "clorosis_pct": round(float(np.count_nonzero(chlorosis)) / expected_area * 100, 1),
        "necrosis_pct": round(float(np.count_nonzero(necrosis)) / expected_area * 100, 1),
        "defoliacion_pct": round(float(np.count_nonzero(holes)) / expected_area * 100, 1),
    }
    return mask3, min(severity, 100.0), components


def level_from_pct(pct: float) -> str:
    if pct < 5:
        return "minima"
    if pct < 15:
        return "leve"
    if pct < 35:
        return "moderada"
    if pct < 60:
        return "severa"
    return "critica"
