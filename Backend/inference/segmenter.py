import base64
import cv2
import numpy as np
import tensorflow as tf


def gray_world(image_rgb: np.ndarray) -> np.ndarray:
    result = image_rgb.astype(np.float32)
    avg = result.reshape(-1, 3).mean(axis=0)
    scale = avg.mean() / (avg + 1e-6)
    return np.clip(result * scale, 0, 255).astype(np.uint8)


def run_segmentation(interp: tf.lite.Interpreter, image_bgr: np.ndarray) -> dict | None:
    image_rgb = gray_world(cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB))
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    resized = cv2.resize(image_rgb, (256, 256))
    tensor = resized[np.newaxis].astype(inp["dtype"])
    interp.set_tensor(inp["index"], tensor)
    interp.invoke()
    raw = interp.get_tensor(out["index"])[0]
    arr = raw.reshape(256, 256, -1) if raw.ndim == 1 else raw
    mask = np.argmax(arr, axis=-1).astype(np.uint8) if arr.ndim == 3 else arr.astype(np.uint8)
    return {
        "b64": base64.b64encode(mask.flatten().tobytes()).decode("ascii"),
        "severity": _compute_severity(mask),
    }


def _compute_severity(mask: np.ndarray) -> float:
    leaf = int(np.sum(mask > 0))
    diseased = int(np.sum(mask == 2))
    return round(diseased / leaf * 100, 1) if leaf > 0 else 0.0
