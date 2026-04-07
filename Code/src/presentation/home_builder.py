from typing import Callable

import flet as ft

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
        return ft.Container(
            expand=True,
            border_radius=24,
            padding=16,
            bgcolor="#edf2f4",
            border=ft.border.all(1, "#d7e3e6"),
            content=ft.Column(
                spacing=14,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                controls=[
                    ft.Text("Selecciona una imagen de soya para iniciar", size=16, weight=ft.FontWeight.W_600, color="#0f3f45", text_align=ft.TextAlign.CENTER),
                    ft.Text("Camara lista para captura" if state.camera_armed else "", size=13, weight=ft.FontWeight.W_500, color="#1d7f87", text_align=ft.TextAlign.CENTER),
                    self._preview.build(state.current_image),
                    ft.Column(
                        spacing=9,
                        controls=[
                            ft.ElevatedButton("Subir imagen", icon=ft.Icons.UPLOAD_FILE, width=330, height=42, on_click=on_pick, bgcolor="#1d7f87", color=ft.Colors.WHITE, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=18), padding=10)),
                            ft.ElevatedButton("Abrir camara", icon=ft.Icons.CAMERA_ALT, width=330, height=42, on_click=on_camera, bgcolor="#2a9d97", color=ft.Colors.WHITE, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=18), padding=10)),
                            ft.ElevatedButton("Detectar salud", icon=ft.Icons.HEALTH_AND_SAFETY, width=330, height=44, disabled=(state.current_image is None and not state.camera_armed), on_click=on_detect, bgcolor="#0f6b73", color=ft.Colors.WHITE, style=ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=20), padding=10)),
                        ],
                    ),
                ],
            ),
        )
