from pathlib import Path

from domain.entities import PredictionResult
from domain.protocols import ImageClassifier


class PredictSoyHealthUseCase:
    def __init__(self, classifier: ImageClassifier) -> None:
        self._classifier = classifier

    def execute(self, image_path: Path) -> PredictionResult:
        return self._classifier.classify(image_path)


class PredictDiseaseTypeUseCase:
    def __init__(self, classifier: ImageClassifier) -> None:
        self._classifier = classifier

    def execute(self, image_path: Path) -> PredictionResult:
        return self._classifier.classify(image_path)
