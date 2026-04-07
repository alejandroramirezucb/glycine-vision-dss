import flet as ft

from presentation.layout_factory import LayoutFactory
from presentation.view_state import AppState, Screen, is_healthy_label


class ScreenFactory:
    def __init__(self, layout: LayoutFactory) -> None:
        self._layout = layout

    def build_home(self, state: AppState, on_pick, on_camera, on_detect) -> ft.Control:
        return self._layout.build_home(state, on_pick, on_camera, on_detect)

    def build_health(self, state: AppState, on_disease) -> ft.Control:
        result = state.health_result
        if not result:
            return ft.Text("No hay resultados disponibles.")
        if is_healthy_label(result.top_prediction.label):
            footer = ft.Text("La soya fue detectada como SANA. El flujo termina aqui.", size=16, weight=ft.FontWeight.W_600, color="#0f6b73", text_align=ft.TextAlign.CENTER)
            return self._layout.build_result("Soya sana o enferma", result, "#0f6b73", footer)
        footer = ft.Column(
            spacing=8,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Text("La soya fue detectada como ENFERMA. Puedes continuar al segundo modelo.", size=16, weight=ft.FontWeight.W_600, color="#1a7f89", text_align=ft.TextAlign.CENTER),
                ft.ElevatedButton("Detectar enfermedad", icon=ft.Icons.SCIENCE, on_click=on_disease, bgcolor="#1d7f87", color=ft.Colors.WHITE, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=18), padding=10)),
            ],
        )
        return self._layout.build_result("Soya sana o enferma", result, "#1a7f89", footer)

    def build_disease(self, state: AppState) -> ft.Control:
        result = state.disease_result
        if not result:
            return ft.Text("No hay resultados disponibles.")
        footer = ft.Text("Diagnostico de enfermedad finalizado.", size=16, weight=ft.FontWeight.W_600, color="#2a9d97")
        return self._layout.build_result("Tipo de enfermedad", result, "#2a9d97", footer)

    def build_by_state(self, state: AppState, on_pick, on_camera, on_detect, on_disease) -> ft.Control:
        if state.current_screen == Screen.HOME:
            return self.build_home(state, on_pick, on_camera, on_detect)
        if state.current_screen == Screen.HEALTH_RESULT:
            return self.build_health(state, on_disease)
        if state.current_screen == Screen.DISEASE_RESULT:
            return self.build_disease(state)
        return ft.Text("Pantalla no disponible")
