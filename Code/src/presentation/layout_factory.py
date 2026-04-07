import flet as ft

from domain.entities import PredictionResult
from presentation.header_builder import HeaderBuilder
from presentation.home_builder import HomeBuilder
from presentation.preview_builder import PreviewBuilder
from presentation.result_builder import ResultBuilder
from presentation.view_state import AppState


class LayoutFactory:
    def __init__(self) -> None:
        preview = PreviewBuilder()
        self._header = HeaderBuilder()
        self._home = HomeBuilder(preview)
        self._result = ResultBuilder(preview)

    def build_header(self, can_go_back: bool, on_home, on_back) -> ft.Control:
        return self._header.build(can_go_back, on_home, on_back)

    def build_home(self, state: AppState, on_pick, on_camera, on_detect) -> ft.Control:
        return self._home.build(state, on_pick, on_camera, on_detect)

    def build_result(self, title: str, result: PredictionResult, accent: str, footer: ft.Control) -> ft.Control:
        return self._result.build(title, result, accent, footer)
