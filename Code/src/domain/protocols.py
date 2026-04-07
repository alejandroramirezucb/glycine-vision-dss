from pathlib import Path
from typing import Protocol

from .entities import PredictionResult


class ImageClassifier(Protocol):
    def classify(self, image_path: Path) -> PredictionResult:
        ...
