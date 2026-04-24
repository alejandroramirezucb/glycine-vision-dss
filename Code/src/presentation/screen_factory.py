import flet as ft
from domain.protocols import TreatmentRepository
from presentation import theme
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
            footer = ft.Text("La soya fue detectada como SANA. El flujo termina aquí.",
                             size=14, weight=ft.FontWeight.W_600, color=theme.ACCENT_DARK,
                             text_align=ft.TextAlign.CENTER)
            
            return self._layout.build_result(
                "Soya: sana o enferma", result, theme.ACCENT_DARK, footer, state.current_image)
        
        footer = ft.Container(
            margin=ft.margin.only(top=18),
            content=ft.ElevatedButton(
                "Detectar enfermedad",
                icon=ft.Icons.SCIENCE,
                on_click=on_disease,
                width=theme.BTN_WIDTH,
                height=theme.BTN_HEIGHT,
                bgcolor=theme.ACCENT,
                color=ft.Colors.WHITE,
                style=theme.btn_style(),
            ),
        )
        
        return self._layout.build_result(
            "Soya: sana o enferma", result, theme.ACCENT, footer, state.current_image)

    def build_disease(self, state: AppState, treatment_repo: TreatmentRepository) -> ft.Control:
        result = state.disease_result
        
        if not result:
            return ft.Text("No hay resultados disponibles.")
        
        treatment = treatment_repo.get_by_label(result.top_prediction.label)
        footer = ft.Column(spacing=12, controls=[
            self._layout.build_treatment_card(treatment),
        ])
        
        return self._layout.build_result(
            "Tipo de enfermedad", result, theme.ACCENT_LIGHT, footer, state.current_image)

    def build_by_state(self, state: AppState, on_pick, on_camera, on_detect, on_disease,
                       treatment_repo: TreatmentRepository) -> ft.Control:
        if state.current_screen == Screen.HOME:
            return self.build_home(state, on_pick, on_camera, on_detect)
        if state.current_screen == Screen.HEALTH_RESULT:
            return self.build_health(state, on_disease)
        if state.current_screen == Screen.DISEASE_RESULT:
            return self.build_disease(state, treatment_repo)
        
        return ft.Text("Pantalla no disponible")
