from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class PredictionItem:
    label: str
    confidence: float


@dataclass(frozen=True)
class PredictionResult:
    image_path: Path
    predictions: list[PredictionItem]

    @property
    def top_prediction(self) -> PredictionItem:
        return self.predictions[0]
