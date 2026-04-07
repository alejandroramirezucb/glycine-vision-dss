from pathlib import Path
import flet as ft
from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.camera_capture import OpenCVCameraCapture
from infrastructure.keras_predictor import KerasImageClassifier
from infrastructure.label_loader import load_labels
from presentation.app_factory import SoyDiagnosisAppFactory


def build_classifier(model_dir: Path) -> KerasImageClassifier:
    return KerasImageClassifier(
        model_path=model_dir / "keras_model.h5",
        labels=load_labels(model_dir / "labels.txt"),
    )


def build_app_factory() -> SoyDiagnosisAppFactory:
    project_root = Path(__file__).resolve().parents[2]

    hs_model_dir = project_root / "Models" / "glycine-vision-hs"
    pd_model_dir = project_root / "Models" / "glycine-vision-pd"

    health_classifier = build_classifier(hs_model_dir)
    disease_classifier = build_classifier(pd_model_dir)

    health_use_case = PredictSoyHealthUseCase(health_classifier)
    disease_use_case = PredictDiseaseTypeUseCase(disease_classifier)

    return SoyDiagnosisAppFactory(
        health_use_case=health_use_case,
        disease_use_case=disease_use_case,
        camera_capture=OpenCVCameraCapture(),
    )


def main(page: ft.Page) -> None:
    app = build_app_factory().build(page)
    app.run()


if __name__ == "__main__":
    ft.run(main)
