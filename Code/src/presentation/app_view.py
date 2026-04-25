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
        self._is_mobile = False
        self._messages = SnackbarService(page)
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
        self._page.on_resize = lambda _e: self._render()
        self._render()

    def _render(self) -> None:
        self._page.clean()
        try:
            screen = self._build_screen()
        except Exception as exc:  # noqa: BLE001
            screen = ft.Text(
                f"Error al renderizar pantalla: {exc}",
                size=13, color=ft.Colors.RED_700, selectable=True,
            )
        pw = self._page.width if self._page.width and self._page.width > 0 else theme.PHONE_WIDTH
        shell_w = int(min(pw, theme.PHONE_WIDTH))
        phone_shell = ft.Container(
            width=shell_w,
            padding=10,
            content=ft.Column(
                spacing=12,
                horizontal_alignment=ft.CrossAxisAlignment.STRETCH,
                controls=[
                    self._layout.build_header(
                        self._state.can_go_back,
                        self._controller.go_home,
                        self._controller.go_back,
                    ),
                    screen,
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

    async def _open_camera(self, e: ft.ControlEvent) -> None:
        if self._controller.camera is not None and not self._is_mobile:
            self._controller.capture(e)
            if self._state.camera_armed:
                self._start_preview_task()
            return
        await self._pick_camera_image()

    def _start_preview_task(self) -> None:
        if getattr(self, "_preview_task_running", False):
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
        tmp = Path(gettempdir()) / f"glycine_{f.name or 'upload.jpg'}"
        if f.bytes:
            tmp.write_bytes(f.bytes)
            self._controller.select_file(tmp)
        elif f.path and Path(f.path).exists():
            self._controller.select_file(Path(f.path))
