from pathlib import Path
import numpy as np
from PIL import Image
import tf_keras as keras
from domain.entities import PredictionItem, PredictionResult
from domain.protocols import ImageClassifier


class KerasImageClassifier(ImageClassifier):
    def __init__(self, model_path: Path, labels: list[str]) -> None:
        self._model = keras.models.load_model(model_path, compile=False)
        self._labels = labels
        self._height, self._width = self._resolve_model_size()

    def _resolve_model_size(self) -> tuple[int, int]:
        shape = self._model.input_shape

        if isinstance(shape, list):
            shape = shape[0]

        height = int(shape[1]) if len(shape) > 2 and shape[1] else 224
        width = int(shape[2]) if len(shape) > 2 and shape[2] else 224
        
        return height, width

    def classify(self, image_path: Path) -> PredictionResult:
        img = Image.open(image_path).convert("RGB")
        img = img.resize((self._width, self._height))
        arr = np.asarray(img, dtype=np.float32)
        arr = (arr / 127.5) - 1.0
        arr = np.expand_dims(arr, axis=0)

        scores = self._model.predict(arr, verbose=0)[0]
        
        if np.min(scores) < 0 or abs(float(np.sum(scores)) - 1.0) > 0.05:
            exps = np.exp(scores - np.max(scores))
            scores = exps / np.sum(exps)

        items: list[PredictionItem] = []

        for idx, score in enumerate(scores):
            label = self._labels[idx] if idx < len(self._labels) else f"class_{idx}"
            items.append(PredictionItem(label=label, confidence=float(score)))

        items.sort(key=lambda p: p.confidence, reverse=True)
        
        return PredictionResult(image_path=image_path, predictions=items)
