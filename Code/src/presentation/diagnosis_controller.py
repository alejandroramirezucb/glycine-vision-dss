from pathlib import Path
from tempfile import gettempdir

import flet as ft

from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.camera_capture import CameraCaptureError, OpenCVCameraCapture
from presentation.ui_messages import SnackbarService
from presentation.view_state import AppState, Screen


class DiagnosisController:
    def __init__(self, state: AppState, health: PredictSoyHealthUseCase, disease: PredictDiseaseTypeUseCase, camera: OpenCVCameraCapture, messages: SnackbarService) -> None:
        self._state, self._health, self._disease = state, health, disease
        self._camera, self._messages = camera, messages
        self._render = lambda: None

    def bind(self, render) -> None:
        self._render = render

    def _set_image(self, path: Path, message: str) -> None:
        self._state.current_image = path
        self._state.camera_armed = False
        self._state.clear_results()
        self._messages.show(message)
        self._render()

    def select_file(self, path: Path) -> None:
        self._camera.stop_session()
        self._set_image(path, "Imagen cargada correctamente.")

    def capture(self, _: ft.ControlEvent) -> None:
        try:
            self._camera.start_session()
            stream_path = Path(gettempdir()) / "glycine_vision_stream.jpg"
            self._camera.start_streaming(stream_path)
            self._state.camera_armed = True
            self._state.current_image = stream_path
            self._state.clear_results()
            self._messages.show("Camara en vivo. Presiona Detectar salud para capturar.")
            self._render()
        except CameraCaptureError as ex:
            self._camera.stop_session()
            self._messages.show(str(ex), error=True)

    def detect_health(self, _: ft.ControlEvent) -> None:
        if self._state.camera_armed:
            try:
                image_path = self._camera.capture_current_frame(Path(gettempdir()) / "glycine_vision_capture.jpg")
                self._state.current_image = image_path
                self._state.camera_armed = False
                self._camera.stop_session()
            except CameraCaptureError as ex:
                return self._messages.show(str(ex), error=True)

        if not self._state.current_image:
            return self._messages.show("Primero selecciona o captura una imagen.", error=True)
        try:
            self._state.health_result = self._health.execute(self._state.current_image); self._state.disease_result = None
            self._state.push(Screen.HEALTH_RESULT); self._render()
        except Exception as ex:
            self._messages.show(f"Error al ejecutar modelo 1: {ex}", error=True)

    def detect_disease(self, _: ft.ControlEvent) -> None:
        if not self._state.current_image:
            return self._messages.show("No hay imagen para analizar.", error=True)
        try:
            self._state.disease_result = self._disease.execute(self._state.current_image)
            self._state.push(Screen.DISEASE_RESULT); self._render()
        except Exception as ex:
            self._messages.show(f"Error al ejecutar modelo 2: {ex}", error=True)

    def go_home(self, _: ft.ControlEvent) -> None:
        self._camera.stop_session()
        self._state.go_home(); self._render()

    def go_back(self, _: ft.ControlEvent) -> None:
        self._camera.stop_session()
        self._state.camera_armed = False
        self._state.pop(); self._render()
