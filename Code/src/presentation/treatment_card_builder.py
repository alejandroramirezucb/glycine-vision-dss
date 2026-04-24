import flet as ft
from domain.treatment import Fuente, TreatmentInfo
from presentation import theme

def _section(title: str, body: str) -> ft.Control:
    return ft.Column(spacing=3, controls=[
        ft.Text(title, size=13, weight=ft.FontWeight.W_700, color=theme.ACCENT_DARK),
        ft.Text(body, size=12, color=theme.TEXT_PRIMARY, selectable=True),
    ])

def _urgency_chip(urgencia: str) -> ft.Control:
    color = theme.urgency_color(urgencia)
    label = {"critica": "CRITICA", "alta": "ALTA", "media": "MEDIA"}.get(urgencia.lower(), urgencia.upper())
    return ft.Container(
        padding=ft.padding.symmetric(horizontal=10, vertical=4),
        border_radius=theme.RADIUS_CHIP,
        bgcolor=color,
        content=ft.Text(f"Urgencia: {label}", size=11, weight=ft.FontWeight.W_700, color=ft.Colors.WHITE),
    )

def _fuente_link(f: Fuente) -> ft.Control:
    return ft.Text(
        spans=[ft.TextSpan(
            f"• {f.texto}",
            url=f.url,
            url_target="_blank",
            style=ft.TextStyle(
                size=10,
                color=theme.ACCENT,
                decoration=ft.TextDecoration.UNDERLINE,
            ),
        )],
    )

class TreatmentCardBuilder:
    def build(self, t: TreatmentInfo) -> ft.Control:
        return ft.Column(
            spacing=12,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Text(t.nombre_es, size=16, weight=ft.FontWeight.BOLD, color=theme.ACCENT_DARK,
                        text_align=ft.TextAlign.CENTER),
                ft.Row(controls=[_urgency_chip(t.urgencia)], alignment=ft.MainAxisAlignment.CENTER),
                _section("Patógenos", t.patogenos),
                ft.Divider(height=1, color=theme.BORDER),
                _section("Síntomas", t.sintomas),
                ft.Divider(height=1, color=theme.BORDER),
                _section("Tratamiento Químico", t.quimico),
                _section("Tratamiento Cultural", t.cultural),
                _section("Control Biológico", t.biologico),
                _section("Prevención", t.preventivo),
                ft.Divider(height=1, color=theme.BORDER),
                ft.Text("Fuentes:", size=11, weight=ft.FontWeight.W_600, color=theme.TEXT_MUTED),
                *[_fuente_link(f) for f in t.fuentes],
            ],
        )
