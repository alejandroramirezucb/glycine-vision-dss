from typing import Callable
import flet as ft
from presentation import theme
from presentation.preview_builder import PreviewBuilder
from presentation.view_state import AppState

class HomeBuilder:
    def __init__(self, preview: PreviewBuilder) -> None:
        self._preview = preview

    def build(
        self,
        state: AppState,
        on_pick: Callable[[ft.ControlEvent], None],
        on_camera: Callable[[ft.ControlEvent], None],
        on_detect: Callable[[ft.ControlEvent], None],
    ) -> ft.Control:
        status = ft.Text(
            "Cámara en vivo — presiona Detectar salud para capturar" if state.camera_armed else "",
            size=12, weight=ft.FontWeight.W_500, color=theme.ACCENT, text_align=ft.TextAlign.CENTER,
        )
        detect_disabled = not state.current_image and not state.camera_armed
        
        return ft.Container(
            border_radius=theme.RADIUS_CARD, padding=18,
            bgcolor=theme.BG_CARD, shadow=theme.card_shadow(),
            content=ft.Column(
                spacing=14,
                horizontal_alignment=ft.CrossAxisAlignment.STRETCH,
                controls=[
                    ft.Text("Selecciona o captura una imagen de soya", size=15,
                            weight=ft.FontWeight.W_600, color=theme.TEXT_PRIMARY,
                            text_align=ft.TextAlign.CENTER),
                    status,
                    self._preview.build(state.current_image, is_live=state.camera_armed),
                    ft.Column(spacing=9,
                              horizontal_alignment=ft.CrossAxisAlignment.STRETCH,
                              controls=[
                        ft.ElevatedButton("Subir imagen", icon=ft.Icons.UPLOAD_FILE,
                                          height=theme.BTN_HEIGHT,
                                          on_click=on_pick, bgcolor=theme.ACCENT,
                                          color=ft.Colors.WHITE, style=theme.btn_style()),
                        ft.ElevatedButton("Abrir cámara", icon=ft.Icons.CAMERA_ALT,
                                          height=theme.BTN_HEIGHT,
                                          on_click=on_camera, bgcolor=theme.ACCENT_LIGHT,
                                          color=ft.Colors.WHITE, style=theme.btn_style()),
                        ft.ElevatedButton("Detectar salud", icon=ft.Icons.HEALTH_AND_SAFETY,
                                          height=theme.BTN_HEIGHT,
                                          disabled=detect_disabled, on_click=on_detect,
                                          bgcolor=theme.ACCENT_DARK,
                                          color=ft.Colors.WHITE, style=theme.btn_style()),
                    ]),
                ],
            ),
        )
