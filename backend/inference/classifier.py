import cv2
import numpy as np
import tensorflow as tf

from .quantization import dequantize

_LEAF_INPUT_KEYS = ("hoja", "aislada", "leaf")


class LeafClassifier:
    def __init__(self, interpreter: tf.lite.Interpreter, labels: list[str]):
        self._interp = interpreter
        self._labels = labels

    @property
    def labels(self) -> list[str]:
        return self._labels

    def predict(self, original_rgb: np.ndarray, leaf_rgb: np.ndarray) -> np.ndarray:
        details = self._interp.get_input_details()
        out = self._interp.get_output_details()[0]
        if len(details) == 1:
            self._interp.set_tensor(details[0]["index"], self._prep(original_rgb, details[0]))
        else:
            for detail in details:
                name = detail["name"].lower()
                source = leaf_rgb if any(key in name for key in _LEAF_INPUT_KEYS) else original_rgb
                self._interp.set_tensor(detail["index"], self._prep(source, detail))
        self._interp.invoke()
        raw = self._interp.get_tensor(out["index"])[0]
        return dequantize(raw, out)

    def probability_diseased(self, scores: np.ndarray) -> float:
        expanded = self._expand_binary(scores)
        for index, label in enumerate(self._labels):
            if "enferm" in label.lower():
                return float(expanded[index])
        return float(expanded[0])

    def top(self, scores: np.ndarray, min_confidence: float) -> tuple[str, float] | None:
        if len(scores) == 0:
            return None
        index = int(np.argmax(scores))
        confidence = float(scores[index])
        if confidence < min_confidence or index >= len(self._labels):
            return None
        return self._labels[index], confidence

    def _expand_binary(self, scores: np.ndarray) -> np.ndarray:
        if scores.ndim == 1 and scores.shape[0] == 1 and len(self._labels) == 2:
            return np.array([1.0 - scores[0], scores[0]], dtype=np.float32)
        return scores

    @staticmethod
    def _prep(image_rgb: np.ndarray, detail: dict) -> np.ndarray:
        target_h, target_w = int(detail["shape"][1]), int(detail["shape"][2])
        resized = cv2.resize(image_rgb, (target_w, target_h))
        return resized[np.newaxis].astype(detail["dtype"])
