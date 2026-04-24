from pathlib import Path
from tempfile import gettempdir
import asyncio
import flet as ft
from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from domain.protocols import TreatmentRepository
from presentation import theme
from presentation.diagnosis_controller import DiagnosisController
from presentation.layout_factory import LayoutFactory
from presentation.screen_factory import ScreenFactory
from presentation.ui_messages import SnackbarService
from presentation.view_state import AppState

_MOBILE = {ft.PagePlatform.ANDROID, ft.PagePlatform.IOS}

class SoyDiagnosisApp:
    def __init__(self, page: ft.Page, health_use_case: PredictSoyHealthUseCase,
                 disease_use_case: PredictDiseaseTypeUseCase,
                 camera_capture,
                 treatment_repo: TreatmentRepository) -> None:
        self._page = page
        self._state = AppState()
        self._layout = LayoutFactory()
        self._screens = ScreenFactory(self._layout)
        self._treatment_repo = treatment_repo
        self._controller = DiagnosisController(
            self._state, health_use_case, disease_use_case, camera_capture, SnackbarService(page))
        self._controller.bind(self._render)
        self._preview_task_running = False
        self._is_mobile = False
        self._file_picker = ft.FilePicker()
        self._page.services.append(self._file_picker)

    def run(self) -> None:
        self._is_mobile = self._page.platform in _MOBILE
        self._page.title = "Glycine Vision DSS"
        self._page.padding = 0
        self._page.bgcolor = theme.BG_PAGE
        self._page.spacing = 0
        self._page.scroll = ft.ScrollMode.AUTO
        self._page.theme = ft.Theme(
            scrollbar_theme=ft.ScrollbarTheme(
                thumb_visibility=True,
                thickness=8,
                radius=8,
                thumb_color="rgba(11,63,69,0.38)",
                track_color="rgba(11,63,69,0.08)",
                track_visibility=False,
                cross_axis_margin=0,
                main_axis_margin=2,
            )
        )
        if not self._is_mobile and hasattr(self._page, "window") and self._page.window:
            w = self._page.window
            w.width = w.min_width = w.max_width = 412
            w.height = w.min_height = w.max_height = 780
            w.resizable = False
        self._render()

    def _render(self) -> None:
        self._page.clean()
        phone_shell = ft.Container(
            width=theme.PHONE_WIDTH,
            padding=10,
            content=ft.Column(
                spacing=12,
                controls=[
                    self._layout.build_header(
                        self._state.can_go_back,
                        self._controller.go_home,
                        self._controller.go_back,
                    ),
                    self._build_screen(),
                ],
            ),
        )
        self._page.add(ft.Row(controls=[phone_shell], alignment=ft.MainAxisAlignment.CENTER))
        self._page.update()

    def _build_screen(self) -> ft.Control:
        return self._screens.build_by_state(
            self._state,
            self._pick_image,
            self._open_camera,
            self._controller.detect_health,
            self._controller.detect_disease,
            self._treatment_repo,
        )

    def _open_camera(self, e: ft.ControlEvent) -> None:
        if self._is_mobile:
            self._page.run_task(self._pick_camera_image)
            return
        self._controller.capture(e)
        if self._state.camera_armed:
            self._start_preview_task()

    def _start_preview_task(self) -> None:
        if self._preview_task_running:
            return
        self._preview_task_running = True
        self._page.run_task(self._preview_loop)

    async def _preview_loop(self) -> None:
        try:
            while self._state.camera_armed:
                b64 = self._controller.get_live_frame_b64()
                if b64:
                    self._layout.update_live_preview(b64)
                await asyncio.sleep(0.02)
        finally:
            self._preview_task_running = False

    async def _pick_image(self, _: ft.ControlEvent) -> None:
        files = await self._file_picker.pick_files(
            allow_multiple=False,
            file_type=ft.FilePickerFileType.CUSTOM,
            allowed_extensions=["png", "jpg", "jpeg", "bmp", "webp", "tif", "tiff"],
            with_data=True,
        )
        await self._resolve_picked(files)

    async def _pick_camera_image(self) -> None:
        files = await self._file_picker.pick_files(
            allow_multiple=False,
            file_type=ft.FilePickerFileType.IMAGE,
            with_data=True,
        )
        await self._resolve_picked(files)

    async def _resolve_picked(self, files) -> None:
        if not files:
            return

        f = files[0]
        
        if f.path and Path(f.path).exists():
            self._controller.select_file(Path(f.path))
        elif f.bytes:
            tmp = Path(gettempdir()) / f"glycine_{f.name or 'photo.jpg'}"
            tmp.write_bytes(f.bytes)
            self._controller.select_file(tmp)
