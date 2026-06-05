import numpy as np
import tensorflow as tf


def _run_single(interp: tf.lite.Interpreter, image_rgb: np.ndarray) -> np.ndarray:
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    target_h, target_w = int(inp["shape"][1]), int(inp["shape"][2])
    import cv2
    resized = cv2.resize(image_rgb, (target_w, target_h))
    tensor = resized[np.newaxis].astype(inp["dtype"])
    interp.set_tensor(inp["index"], tensor)
    interp.invoke()
    raw = interp.get_tensor(out["index"])[0]
    return raw.astype(np.float32) / 255.0 if out["dtype"] == np.uint8 else raw.astype(np.float32)


def _expand_binary(scores: np.ndarray, num_labels: int) -> np.ndarray:
    if scores.ndim == 1 and scores.shape[0] == 1 and num_labels == 2:
        return np.array([1.0 - scores[0], scores[0]], dtype=np.float32)
    return scores


def probability_diseased(scores: np.ndarray, labels: list[str]) -> float:
    expanded = _expand_binary(scores, len(labels))
    for i, label in enumerate(labels):
        if "enferm" in label.lower():
            return float(expanded[i])
    return float(expanded[0])


def top_disease(
    scores: np.ndarray,
    labels: list[str],
    min_confidence: float,
) -> tuple[str, float] | None:
    if len(scores) == 0:
        return None
    index = int(np.argmax(scores))
    confidence = float(scores[index])
    if confidence < min_confidence or index >= len(labels):
        return None
    return labels[index], confidence


def run_health(interp: tf.lite.Interpreter, image_rgb: np.ndarray) -> np.ndarray:
    return _run_single(interp, image_rgb)


def run_disease(interp: tf.lite.Interpreter, image_rgb: np.ndarray) -> np.ndarray:
    return _run_single(interp, image_rgb)
