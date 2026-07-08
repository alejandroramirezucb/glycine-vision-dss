import cv2
import numpy as np

_SCALE_LO = 0.6
_SCALE_HI = 1.6


class Preprocessor:
    def __init__(self, minkowski_p: int = 6, mask_size: int = 256):
        self._p = minkowski_p
        self._mask_size = mask_size

    def normalize(self, image_rgb: np.ndarray) -> np.ndarray:
        x = image_rgb.astype(np.float32)
        illum = np.power(np.mean(np.power(x, self._p), axis=(0, 1)), 1.0 / self._p)
        scale = np.clip(illum.mean() / (illum + 1e-6), _SCALE_LO, _SCALE_HI)
        return np.clip(x * scale, 0, 255).astype(np.uint8)

    def isolate(self, image_rgb: np.ndarray, leaf_full_mask: np.ndarray) -> np.ndarray:
        out = image_rgb.copy()
        out[leaf_full_mask == 0] = 0
        return out

    def to_mask_size(self, image_rgb: np.ndarray) -> np.ndarray:
        return cv2.resize(image_rgb, (self._mask_size, self._mask_size))
