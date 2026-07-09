import cv2
import numpy as np
import tensorflow as tf


class LeafSegmenter:
    def __init__(self, interpreter: tf.lite.Interpreter, mask_size: int = 256):
        self._interp = interpreter
        self._size = mask_size

    def segment(self, norm_rgb: np.ndarray) -> np.ndarray:
        inp = self._interp.get_input_details()[0]
        out = self._interp.get_output_details()[0]
        resized = cv2.resize(norm_rgb, (self._size, self._size))
        self._interp.set_tensor(inp["index"], resized[np.newaxis].astype(inp["dtype"]))
        self._interp.invoke()
        raw = self._interp.get_tensor(out["index"])[0]
        arr = raw.reshape(self._size, self._size, -1) if raw.ndim == 1 else raw
        if arr.ndim == 3:
            leaf = (np.argmax(arr, axis=-1) == 1).astype(np.uint8)
        else:
            leaf = (arr > 0).astype(np.uint8)
        return self._largest_component(leaf)

    @staticmethod
    def _largest_component(mask: np.ndarray) -> np.ndarray:
        count, labels, stats, _ = cv2.connectedComponentsWithStats(mask.astype(np.uint8), connectivity=8)
        if count <= 2:
            return mask
        areas = stats[1:, cv2.CC_STAT_AREA]
        keep = 1 + int(np.argmax(areas))
        threshold = 0.15 * float(areas.max())
        out = np.isin(labels, [i + 1 for i, a in enumerate(areas) if a >= threshold or i + 1 == keep])
        return out.astype(np.uint8)
