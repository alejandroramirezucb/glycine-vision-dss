from typing import Callable
import flet as ft
from presentation import theme

class HeaderBuilder:
    def build(
        self,
        can_go_back: bool,
        on_home: Callable[[ft.ControlEvent], None],
        on_back: Callable[[ft.ControlEvent], None],
    ) -> ft.Control:
        btn_style = ft.ButtonStyle(
            shape=ft.RoundedRectangleBorder(radius=theme.RADIUS_CHIP),
            padding=ft.padding.symmetric(horizontal=12, vertical=0),
        )
        actions: list[ft.Control] = [
            ft.ElevatedButton("Inicio", icon=ft.Icons.HOME, on_click=on_home,
                              bgcolor=theme.ACCENT_LIGHT, color=ft.Colors.WHITE,
                              height=36, style=btn_style),
        ]
        if can_go_back:
            actions.insert(0, ft.ElevatedButton("Volver", icon=ft.Icons.ARROW_BACK,
                                                on_click=on_back, bgcolor=theme.ACCENT,
                                                color=ft.Colors.WHITE, height=36,
                                                style=btn_style))
        
        return ft.Container(
            bgcolor=theme.BG_CARD,
            border_radius=theme.RADIUS_CARD,
            padding=ft.padding.symmetric(horizontal=14, vertical=10),
            shadow=theme.card_shadow(),
            content=ft.Row(
                controls=[
                    ft.Text("Glycine Vision", size=17, weight=ft.FontWeight.W_700,
                            color=theme.ACCENT_DARK, expand=True),
                    ft.Row(controls=actions, tight=True,
                           alignment=ft.MainAxisAlignment.END),
                ],
                alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                vertical_alignment=ft.CrossAxisAlignment.CENTER,
            ),
        )
