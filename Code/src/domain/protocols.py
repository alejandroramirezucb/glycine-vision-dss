from pathlib import Path
from typing import TYPE_CHECKING, Protocol
from .entities import PredictionResult

if TYPE_CHECKING:
    from .treatment import TreatmentInfo

class ImageClassifier(Protocol):
    def classify(self, image_path: Path) -> PredictionResult:
        ...

class TreatmentRepository(Protocol):
    def get_by_label(self, label: str) -> "TreatmentInfo | None":
        ...
