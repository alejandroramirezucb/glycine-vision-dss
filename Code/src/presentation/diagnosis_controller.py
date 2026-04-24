from collections.abc import Callable
from pathlib import Path
from tempfile import gettempdir
import flet as ft
from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from presentation.ui_messages import SnackbarService
from presentation.view_state import AppState, Screen

_STREAM_PATH = Path(gettempdir()) / "glycine_vision_stream.jpg"
_CAPTURE_PATH = Path(gettempdir()) / "glycine_vision_capture.jpg"

class DiagnosisController:
    def __init__(self, state: AppState, health: PredictSoyHealthUseCase,
                 disease: PredictDiseaseTypeUseCase, camera,
                 messages: SnackbarService) -> None:
        self._state, self._health, self._disease = state, health, disease
        self._camera, self._messages = camera, messages
        self._render: Callable = lambda: None

    @property
    def camera(self):
        return self._camera

    def bind(self, render: Callable) -> None:
        self._render = render

    def get_live_frame_b64(self) -> str | None:
        return self._camera.get_current_b64() if self._camera else None

    def select_file(self, path: Path) -> None:
        if self._camera:
            self._camera.stop_session()

        self._state.current_image = path
        self._state.camera_armed = False
        self._state.clear_results()
        self._messages.show("Imagen cargada correctamente.")
        self._render()

    def capture(self, _: ft.ControlEvent) -> None:
        if not self._camera:
            return

        try:
            self._camera.start_session()
            self._camera.start_streaming(_STREAM_PATH)
            self._state.camera_armed = True
            self._state.current_image = _STREAM_PATH
            self._state.clear_results()
            self._messages.show("Cámara en vivo. Presiona Detectar salud para capturar.")
            self._render()
        except Exception as ex:
            self._camera.stop_session()
            self._messages.show(str(ex), error=True)

    def detect_health(self, _: ft.ControlEvent) -> None:
        if self._state.camera_armed and self._camera:
            try:
                self._state.current_image = self._camera.capture_current_frame(_CAPTURE_PATH)
                self._state.camera_armed = False
                self._camera.stop_session()
            except Exception as ex:
                return self._messages.show(str(ex), error=True)

        if not self._state.current_image:
            return self._messages.show("Primero selecciona o captura una imagen.", error=True)

        try:
            self._state.health_result = self._health.execute(self._state.current_image)
            self._state.disease_result = None
            self._state.push(Screen.HEALTH_RESULT)
            self._render()
        except Exception as ex:
            self._messages.show(f"Error modelo 1: {ex}", error=True)

    def detect_disease(self, _: ft.ControlEvent) -> None:
        if not self._state.current_image:
            return self._messages.show("No hay imagen para analizar.", error=True)

        try:
            self._state.disease_result = self._disease.execute(self._state.current_image)
            self._state.push(Screen.DISEASE_RESULT)
            self._render()
        except Exception as ex:
            self._messages.show(f"Error modelo 2: {ex}", error=True)

    def go_home(self, _: ft.ControlEvent) -> None:
        if self._camera:
            self._camera.stop_session()

        self._state.go_home()
        self._render()

    def go_back(self, _: ft.ControlEvent) -> None:
        if self._camera:
            self._camera.stop_session()

        self._state.camera_armed = False
        self._state.pop()

        if self._state.current_screen == Screen.HOME:
            self._state.go_home()

        self._render()
