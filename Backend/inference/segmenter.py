import cv2
import numpy as np
import tensorflow as tf

_SCALE_LO = 0.6
_SCALE_HI = 1.6
_MASK_SIZE = 256


def shades_of_gray(image_rgb: np.ndarray, p: int = 6) -> np.ndarray:
    x = image_rgb.astype(np.float32)
    illum = np.power(np.mean(np.power(x, p), axis=(0, 1)), 1.0 / p)
    scale = np.clip(illum.mean() / (illum + 1e-6), _SCALE_LO, _SCALE_HI)
    return np.clip(x * scale, 0, 255).astype(np.uint8)


def _largest_component(mask: np.ndarray) -> np.ndarray:
    count, labels, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), connectivity=8)
    if count <= 2:
        return mask
    areas = stats[1:, cv2.CC_STAT_AREA]
    keep = 1 + int(np.argmax(areas))
    threshold = 0.15 * float(areas.max())
    out = np.isin(labels, [i + 1 for i, a in enumerate(areas) if a >= threshold or i + 1 == keep])
    return out.astype(np.uint8)


def segment_leaf(interp: tf.lite.Interpreter, image_bgr: np.ndarray) -> np.ndarray:
    rgb = shades_of_gray(cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB))
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    resized = cv2.resize(rgb, (_MASK_SIZE, _MASK_SIZE))
    interp.set_tensor(inp["index"], resized[np.newaxis].astype(inp["dtype"]))
    interp.invoke()
    raw = interp.get_tensor(out["index"])[0]
    arr = raw.reshape(_MASK_SIZE, _MASK_SIZE, -1) if raw.ndim == 1 else raw
    leaf = np.argmax(arr, axis=-1) if arr.ndim == 3 else arr
    leaf = (leaf == 1).astype(np.uint8) if arr.ndim == 3 else (leaf > 0).astype(np.uint8)
    return _largest_component(leaf)
