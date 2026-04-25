import flet as ft
from domain.entities import PredictionResult
from domain.treatment import TreatmentInfo
from presentation.header_builder import HeaderBuilder
from presentation.home_builder import HomeBuilder
from presentation.preview_builder import PreviewBuilder
from presentation.result_builder import ResultBuilder
from presentation.treatment_card_builder import TreatmentCardBuilder
from presentation.view_state import AppState
from pathlib import Path

class LayoutFactory:
    def __init__(self) -> None:
        self._preview = PreviewBuilder()
        self._header = HeaderBuilder()
        self._home = HomeBuilder(self._preview)
        self._result = ResultBuilder()
        self._treatment = TreatmentCardBuilder()

    def build_header(self, can_go_back: bool, on_home, on_back) -> ft.Control:
        return self._header.build(can_go_back, on_home, on_back)

    def build_home(self, state: AppState, on_pick, on_camera, on_detect) -> ft.Control:
        return self._home.build(state, on_pick, on_camera, on_detect)

    def build_result(self, title: str, result: PredictionResult, accent: str,
                     footer: ft.Control, image_path: Path | None = None) -> ft.Control:
        return self._result.build(title, result, accent, footer, image_path)

    def build_treatment_card(self, t: TreatmentInfo | None) -> ft.Control:
        if t is None:
            return ft.Text("Información de tratamiento no disponible.", size=13)
        
        return self._treatment.build(t)

    def update_live_preview(self, b64: str) -> None:
        self._preview.update_live_frame(b64)

    def reset_live_preview(self) -> None:
        self._preview.reset_live()

    def update_flet_camera(self, cam) -> None:
        self._preview.set_flet_camera(cam)
