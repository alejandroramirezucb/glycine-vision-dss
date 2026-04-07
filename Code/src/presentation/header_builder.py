from typing import Callable

import flet as ft


class HeaderBuilder:
    def build(
        self,
        can_go_back: bool,
        on_home: Callable[[ft.ControlEvent], None],
        on_back: Callable[[ft.ControlEvent], None],
    ) -> ft.Control:
        style = ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=16), padding=10)
        actions: list[ft.Control] = [ft.ElevatedButton("Inicio", icon=ft.Icons.HOME, on_click=on_home, bgcolor="#2a9d97", color=ft.Colors.WHITE, height=36, style=style)]
        if can_go_back:
            actions.insert(0, ft.ElevatedButton("Volver", icon=ft.Icons.ARROW_BACK, on_click=on_back, bgcolor="#1d7f87", color=ft.Colors.WHITE, height=36, style=style))
        return ft.Container(
            bgcolor="#edf2f4",
            border_radius=22,
            padding=10,
            border=ft.border.all(1, "#d7e3e6"),
            content=ft.Row(
                controls=[
                    ft.Text("Glycine Vision", size=19, weight=ft.FontWeight.W_700, color="#0b5b61"),
                    ft.Row(controls=actions, alignment=ft.MainAxisAlignment.END),
                ],
                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
        )
