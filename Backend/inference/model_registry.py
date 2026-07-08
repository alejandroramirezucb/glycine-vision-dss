from pathlib import Path
from typing import Optional

import tensorflow as tf

from config import MODELS_DIR, TFLITE_THREADS
from inference.classifier import LeafClassifier
from inference.segmenter import LeafSegmenter


class ModelRegistry:
    def __init__(self, models_dir: Path = MODELS_DIR):
        self._dir = models_dir
        self.health = LeafClassifier(self._load("health/model_int8.tflite"), self._load_labels("health/labels.txt"))
        self.disease = LeafClassifier(self._load("disease/model_int8.tflite"), self._load_labels("disease/labels.txt"))
        segmenter = self._try_load("segmentation/model_int8.tflite")
        self.segmenter: Optional[LeafSegmenter] = LeafSegmenter(segmenter) if segmenter is not None else None

    def _load(self, name: str) -> tf.lite.Interpreter:
        interpreter = tf.lite.Interpreter(model_path=str(self._dir / name), num_threads=TFLITE_THREADS)
        interpreter.allocate_tensors()
        return interpreter

    def _try_load(self, name: str) -> Optional[tf.lite.Interpreter]:
        try:
            return self._load(name)
        except Exception as error:
            print(f"[warn] Optional model not loaded ({name}): {error}")
            return None

    def _load_labels(self, name: str) -> list[str]:
        labels = []
        for line in (self._dir / name).read_text(encoding="utf-8").splitlines():
            stripped = line.strip()
            if not stripped:
                continue
            parts = stripped.split(" ", 1)
            labels.append(parts[1] if len(parts) == 2 and parts[0].isdigit() else stripped)
        return labels
