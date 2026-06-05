import json
from pathlib import Path
import tensorflow as tf
from config import MODELS_DIR, TFLITE_THREADS


class ModelRegistry:
    def __init__(self, models_dir: Path = MODELS_DIR):
        self._dir = models_dir
        self.health = self._load("health/model_int8.tflite")
        self.health_labels = self._load_labels("health/labels.txt")
        self.disease = self._load("disease/model_int8.tflite")
        self.disease_labels = self._load_labels("disease/labels.txt")
        self.disease_thresholds = self._load_thresholds("disease/thresholds.json", self.disease_labels)
        self.segmenter = self._try_load("segmentation/model_int8.tflite")

    def _load(self, name: str) -> tf.lite.Interpreter:
        path = self._dir / name
        interp = tf.lite.Interpreter(model_path=str(path), num_threads=TFLITE_THREADS)
        interp.allocate_tensors()
        return interp

    def _try_load(self, name: str) -> tf.lite.Interpreter | None:
        try:
            return self._load(name)
        except Exception as e:
            print(f"[warn] Optional model not loaded ({name}): {e}")
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

    def _load_thresholds(self, name: str, labels: list[str]) -> dict[str, float]:
        path = self._dir / name
        if not path.exists():
            return {label: 0.5 for label in labels}
        raw = json.loads(path.read_text(encoding="utf-8"))
        return {label: float(raw.get(label, 0.5)) for label in labels}
