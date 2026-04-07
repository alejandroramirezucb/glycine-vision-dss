import flet as ft

from domain.entities import PredictionResult
from presentation.preview_builder import PreviewBuilder


class ResultBuilder:
    def __init__(self, preview: PreviewBuilder) -> None:
        self._preview = preview

    def _capitalize(self, text: str) -> str:
        return text[:1].upper() + text[1:] if text else text

    def _normalize(self, text: str) -> str:
        cleaned = text.strip().replace("_", " ").replace("-", " ").replace(".", " ")
        parts = [p for p in cleaned.split() if p]
        if parts and parts[0].isdigit():
            parts = parts[1:]
        return " ".join(parts).lower()

    def _translate_token(self, token: str) -> str:
        key = self._normalize(token)
        mapped = {
            "healthy": "Sana",
            "diseased": "Enferma",
            "bacterial diseases": "Bacterianas",
            "fungal diseases": "Fungicas",
            "rust disease": "Roya",
            "viral diseases": "Virales",
            "insect pests": "Plagas",
        }
        return mapped.get(key, self._capitalize(key))

    def _label_es(self, label: str) -> str:
        if "+" in label:
            return " + ".join(self._translate_token(part) for part in label.split("+"))
        return self._translate_token(label)

    def build(self, title: str, result: PredictionResult, accent: str, footer: ft.Control) -> ft.Control:
        rows = [
            ft.Container(
                width=300,
                content=ft.Column(
                    spacing=4,
                    controls=[
                        ft.Row(
                            alignment=ft.MainAxisAlignment.SPACE_BETWEEN,
                            controls=[
                                ft.Text(self._label_es(x.label), size=14, weight=ft.FontWeight.W_600, color="#134e55"),
                                ft.Text(f"{x.confidence * 100:.2f}%", size=14, weight=ft.FontWeight.W_700, color="#0f6b73"),
                            ],
                        ),
                        ft.ProgressBar(value=max(0.0, min(1.0, x.confidence)), color=accent),
                    ],
                ),
            )
            for x in result.predictions
        ]
        return ft.Column(
            spacing=12,
            horizontal_alignment=ft.CrossAxisAlignment.CENTER,
            controls=[
                ft.Container(
                    width=350,
                    border_radius=14,
                    padding=14,
                    bgcolor="#edf2f4",
                    border=ft.border.all(1, "#d7e3e6"),
                    content=ft.Column(
                        spacing=10,
                        horizontal_alignment=ft.CrossAxisAlignment.CENTER,
                        controls=[
                            ft.Text(title, size=18, weight=ft.FontWeight.BOLD, color=accent, text_align=ft.TextAlign.CENTER),
                            ft.Text(f"Mayor probabilidad: {self._label_es(result.top_prediction.label)} ({result.top_prediction.confidence * 100:.2f}%)", size=14, weight=ft.FontWeight.W_600, color="#0f3f45", text_align=ft.TextAlign.CENTER),
                            self._preview.build(result.image_path),
                            *rows,
                        ],
                    ),
                ),
                footer,
            ],
        )
