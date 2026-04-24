import os
from pathlib import Path
import flet as ft
from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.keras_predictor import KerasImageClassifier
from infrastructure.label_loader import load_labels
from presentation.app_factory import SoyDiagnosisAppFactory

_MOBILE = {ft.PagePlatform.ANDROID, ft.PagePlatform.IOS}
_WEB_MODE = os.environ.get("GLYCINE_WEB") == "1"

def _project_root() -> Path:
    env = os.environ.get("GLYCINE_ROOT")
    return Path(env) if env else Path(__file__).resolve().parents[2]

def _build_classifier(model_dir: Path) -> KerasImageClassifier:
    return KerasImageClassifier(
        model_path=model_dir / "keras_model.h5",
        labels=load_labels(model_dir / "labels.txt"),
    )

def _create_camera(page: ft.Page):
    if _WEB_MODE or page.platform in _MOBILE:
        return None
    try:
        from infrastructure.camera_capture import OpenCVCameraCapture
        return OpenCVCameraCapture()
    except ImportError:
        return None

def main(page: ft.Page) -> None:
    root = _project_root()
    health_clf = _build_classifier(root / "Models" / "glycine-vision-hs")
    disease_clf = _build_classifier(root / "Models" / "glycine-vision-pd")

    SoyDiagnosisAppFactory(
        health_use_case=PredictSoyHealthUseCase(health_clf),
        disease_use_case=PredictDiseaseTypeUseCase(disease_clf),
        camera_capture=_create_camera(page),
    ).build(page).run()

if __name__ == "__main__":
    port = int(os.environ.get("GLYCINE_PORT", "8550"))
    if _WEB_MODE:
        ft.run(main, view=ft.AppView.WEB_BROWSER, host="0.0.0.0", port=port)
    else:
        ft.run(main)
