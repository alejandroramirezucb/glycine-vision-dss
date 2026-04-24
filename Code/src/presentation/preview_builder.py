from pathlib import Path
import flet as ft
from presentation import theme

class PreviewBuilder:
    def __init__(self) -> None:
        self._live_image: ft.Image | None = None
        self._placeholder_src = "data:image/gif;base64,R0lGODlhAQABAIAAAAAAAP///ywAAAAAAQABAAACAUwAOw=="

    def _get_or_create_live(self, src_hint: str | None = None) -> ft.Image:
        if self._live_image is None:
            self._live_image = ft.Image(
                src=src_hint or self._placeholder_src,
                height=theme.IMG_HEIGHT,
                fit=ft.BoxFit.CONTAIN,
                gapless_playback=True,
            )
        
        return self._live_image

    def update_live_frame(self, b64: str) -> None:
        img = self._get_or_create_live()
        img.src = f"data:image/jpeg;base64,{b64}"
        
        if img.page:
            img.update()

    def reset_live(self) -> None:
        self._live_image = None

    def build(self, path: Path | None, is_live: bool = False) -> ft.Control:
        if is_live:
            return ft.Container(
                border_radius=theme.RADIUS_IMG,
                clip_behavior=ft.ClipBehavior.HARD_EDGE,
                shadow=theme.card_shadow(),
                content=self._get_or_create_live(),
            )
        
        if not path:
            return ft.Container(
                height=theme.IMG_HEIGHT,
                border_radius=theme.RADIUS_IMG,
                bgcolor="#D4E2E6",
                border=ft.border.all(1, theme.BORDER),
                alignment=ft.Alignment(0, 0),
                content=ft.Text("Sin imagen seleccionada", color=theme.TEXT_MUTED,
                                weight=ft.FontWeight.W_500),
            )
        
        return ft.Container(
            border_radius=theme.RADIUS_IMG,
            clip_behavior=ft.ClipBehavior.HARD_EDGE,
            shadow=theme.card_shadow(),
            content=ft.Image(src=str(path), height=theme.IMG_HEIGHT, fit=ft.BoxFit.CONTAIN),
        )
