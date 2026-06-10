import cv2
import numpy as np
import tensorflow as tf

_LEAF_INPUT_KEYS = ("hoja", "aislada", "leaf")


def _prep(image_rgb: np.ndarray, detail: dict) -> np.ndarray:
    target_h, target_w = int(detail["shape"][1]), int(detail["shape"][2])
    resized = cv2.resize(image_rgb, (target_w, target_h))
    return resized[np.newaxis].astype(detail["dtype"])


def _run(interp: tf.lite.Interpreter, original_rgb: np.ndarray, leaf_rgb: np.ndarray) -> np.ndarray:
    details = interp.get_input_details()
    out = interp.get_output_details()[0]
    if len(details) == 1:
        interp.set_tensor(details[0]["index"], _prep(original_rgb, details[0]))
    else:
        for d in details:
            name = d["name"].lower()
            src = leaf_rgb if any(k in name for k in _LEAF_INPUT_KEYS) else original_rgb
            interp.set_tensor(d["index"], _prep(src, d))
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


def run_health(interp: tf.lite.Interpreter, original_rgb: np.ndarray, leaf_rgb: np.ndarray) -> np.ndarray:
    return _run(interp, original_rgb, leaf_rgb)


def run_disease(interp: tf.lite.Interpreter, original_rgb: np.ndarray, leaf_rgb: np.ndarray) -> np.ndarray:
    return _run(interp, original_rgb, leaf_rgb)
