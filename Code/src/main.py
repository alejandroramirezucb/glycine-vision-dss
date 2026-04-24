from pathlib import Path
import flet as ft
from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.keras_predictor import KerasImageClassifier
from infrastructure.label_loader import load_labels
from presentation.app_factory import SoyDiagnosisAppFactory

_MOBILE = {ft.PagePlatform.ANDROID, ft.PagePlatform.IOS}

def _build_classifier(model_dir: Path) -> KerasImageClassifier:
    return KerasImageClassifier(
        model_path=model_dir / "keras_model.h5",
        labels=load_labels(model_dir / "labels.txt"),
    )

def main(page: ft.Page) -> None:
    project_root = Path(__file__).resolve().parents[2]
    health_clf = _build_classifier(project_root / "Models" / "glycine-vision-hs")
    disease_clf = _build_classifier(project_root / "Models" / "glycine-vision-pd")

    camera = None
    
    if page.platform not in _MOBILE:
        from infrastructure.camera_capture import OpenCVCameraCapture
        camera = OpenCVCameraCapture()

    SoyDiagnosisAppFactory(
        health_use_case=PredictSoyHealthUseCase(health_clf),
        disease_use_case=PredictDiseaseTypeUseCase(disease_clf),
        camera_capture=camera,
    ).build(page).run()


if __name__ == "__main__":
    ft.run(main)
