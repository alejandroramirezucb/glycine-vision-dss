import flet as ft

from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.camera_capture import OpenCVCameraCapture
from presentation.app_view import SoyDiagnosisApp


class SoyDiagnosisAppFactory:
    def __init__(self, health_use_case: PredictSoyHealthUseCase, disease_use_case: PredictDiseaseTypeUseCase, camera_capture: OpenCVCameraCapture) -> None:
        self._health_use_case = health_use_case
        self._disease_use_case = disease_use_case
        self._camera_capture = camera_capture

    def build(self, page: ft.Page) -> SoyDiagnosisApp:
        return SoyDiagnosisApp(
            page=page,
            health_use_case=self._health_use_case,
            disease_use_case=self._disease_use_case,
            camera_capture=self._camera_capture,
        )
