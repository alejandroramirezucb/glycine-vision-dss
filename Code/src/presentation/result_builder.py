import flet as ft
from pathlib import Path
from domain.entities import PredictionResult
from presentation import theme

_LABEL_MAP = {
    "healthy": "Sana", "diseased": "Enferma",
    "bacterial diseases": "Bacterianas", "fungal diseases": "Fungicas",
    "rust disease": "Roya", "viral diseases": "Virales", "insect pests": "Plagas",
}

def _normalize(text: str) -> str:
    parts = text.strip().replace("_", " ").replace("-", " ").split()
    
    if parts and parts[0].isdigit():
        parts = parts[1:]
    
    return " ".join(parts).lower()

def _label_es(label: str) -> str:
    if "+" in label:
        return " + ".join(_label_es(p) for p in label.split("+"))
    
    key = _normalize(label)
    mapped = _LABEL_MAP.get(key, key)
    
    return mapped[:1].upper() + mapped[1:]

class ResultBuilder:
    def build(self, title: str, result: PredictionResult, accent: str, footer: ft.Control,
              image_path: Path | None = None) -> ft.Control:
        rows = [
            ft.Container(width=330, content=ft.Column(spacing=4, controls=[
                ft.Row(alignment=ft.MainAxisAlignment.SPACE_BETWEEN, controls=[
                    ft.Text(_label_es(x.label), size=14, weight=ft.FontWeight.W_600, color=theme.TEXT_PRIMARY),
                    ft.Text(f"{x.confidence * 100:.1f}%", size=14, weight=ft.FontWeight.W_700, color=accent),
                ]),
                ft.ProgressBar(value=max(0.0, min(1.0, x.confidence)), color=accent),
            ]))
            
            for x in result.predictions
        ]
        
        top = result.top_prediction
        preview = ft.Container()

        if image_path:
            preview = ft.Container(
                border_radius=theme.RADIUS_IMG,
                clip_behavior=ft.ClipBehavior.HARD_EDGE,
                shadow=theme.card_shadow(),
                content=ft.Image(src=str(image_path), height=theme.IMG_HEIGHT, fit=ft.BoxFit.CONTAIN),
            )
        
        return ft.Container(
            width=theme.CARD_WIDTH,
            border_radius=theme.RADIUS_CARD,
            bgcolor=theme.BG_CARD,
            padding=18,
            shadow=theme.card_shadow(),
            content=ft.Column(
                spacing=12,
                horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                controls=[
                    ft.Text(title, size=18, weight=ft.FontWeight.BOLD, color=accent,
                            text_align=ft.TextAlign.CENTER),
                    preview,
                    ft.Text(f"Mayor probabilidad: {_label_es(top.label)} ({top.confidence * 100:.1f}%)",
                            size=13, weight=ft.FontWeight.W_600, color=theme.TEXT_PRIMARY,
                            text_align=ft.TextAlign.CENTER),
                    ft.Container(height=8),
                    *rows,
                    footer,
                ],
            ),
        )
