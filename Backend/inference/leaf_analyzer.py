import cv2
import numpy as np

_HSV_GREEN = (np.array([20, 30, 30]), np.array([90, 255, 255]))
_HSV_LESION = [
    (np.array([10, 50, 20]), np.array([30, 255, 200])),
    (np.array([0, 50, 20]), np.array([10, 255, 180])),
]
_HSV_NECROTIC = [(np.array([0, 0, 0]), np.array([180, 80, 60]))]
_SEVERITY_LEVELS = ("minima", "leve", "moderada", "severa", "critica")


def severity_hsv(image_bgr: np.ndarray) -> tuple[float, str]:
    hsv = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2HSV)
    healthy = cv2.inRange(hsv, _HSV_GREEN[0], _HSV_GREEN[1])
    diseased = _union_masks(hsv, _HSV_LESION + _HSV_NECROTIC)
    kernel = np.ones((3, 3), np.uint8)
    diseased = cv2.morphologyEx(diseased, cv2.MORPH_OPEN, kernel)
    diseased = cv2.morphologyEx(diseased, cv2.MORPH_CLOSE, kernel)
    leaf = cv2.bitwise_or(healthy, diseased)
    total = image_bgr.shape[0] * image_bgr.shape[1]
    leaf_px = int(cv2.countNonZero(leaf))
    if leaf_px < total * 0.1:
        return 0.0, "minima"
    pct = round(min(int(cv2.countNonZero(diseased)) / leaf_px * 100, 100.0), 1)
    return pct, _level_from_pct(pct)


def _union_masks(hsv: np.ndarray, ranges: list) -> np.ndarray:
    mask = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for lo, hi in ranges:
        mask = cv2.bitwise_or(mask, cv2.inRange(hsv, lo, hi))
    return mask


def _level_from_pct(pct: float) -> str:
    if pct < 5:
        return "minima"
    if pct < 15:
        return "leve"
    if pct < 35:
        return "moderada"
    if pct < 60:
        return "severa"
    return "critica"
