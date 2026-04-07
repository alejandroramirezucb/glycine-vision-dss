from pathlib import Path

import flet as ft


class PreviewBuilder:
    def build(self, path: Path | None) -> ft.Control:
        if not path:
            return ft.Container(
                height=260,
                border_radius=20,
                bgcolor="#d9e5e8",
                border=ft.border.all(1, "#d7e3e6"),
                alignment=ft.Alignment(0, 0),
                content=ft.Text("Sin imagen seleccionada", color="#0f4f57", weight=ft.FontWeight.W_500),
            )
        return ft.Container(
            border_radius=20,
            clip_behavior=ft.ClipBehavior.HARD_EDGE,
            border=ft.border.all(1, "#d7e3e6"),
            content=ft.Image(src=str(path), height=260, fit=ft.BoxFit.CONTAIN),
        )
