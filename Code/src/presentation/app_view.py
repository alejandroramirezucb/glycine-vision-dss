import base64
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
_CAPTURE_PATH = Path(gettempdir()) / "glycine_web_capture.jpg"

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
        self._flet_camera = None
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
        # Clear web camera if no longer armed
        if not self._state.camera_armed and self._flet_camera is not None:
            self._flet_camera = None
            self._layout.update_flet_camera(None)
        self._page.clean()
        try:
            screen = self._build_screen()
        except Exception as exc:  # noqa: BLE001
            screen = ft.Text(
                f"Error al renderizar pantalla: {exc}",
                size=13, color=ft.Colors.RED_700, selectable=True,
            )
        # shell_w: actual phone width on mobile, capped at PHONE_WIDTH on desktop/laptop
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
        on_detect = (
            self._capture_and_detect
            if self._state.camera_armed and self._flet_camera is not None
            else self._controller.detect_health
        )
        return self._screens.build_by_state(
            self._state,
            self._pick_image,
            self._open_camera,
            on_detect,
            self._controller.detect_disease,
            self._treatment_repo,
        )

    async def _open_camera(self, e: ft.ControlEvent) -> None:
        if self._is_mobile or self._controller.camera is None:
            await self._start_web_camera()
            return
        self._controller.capture(e)
        if self._state.camera_armed:
            self._start_preview_task()

    async def _start_web_camera(self) -> None:
        try:
            from flet_camera import Camera as _FletCamera
            cam = _FletCamera()
        except Exception:
            # flet-camera not installed — fall back to file picker
            await self._pick_camera_image()
            return
        self._flet_camera = cam
        self._layout.update_flet_camera(cam)
        self._state.camera_armed = True
        self._state.current_image = None
        self._state.clear_results()
        self._render()
        await asyncio.sleep(0.5)  # let browser attach widget before initialize
        try:
            cameras = await cam.get_available_cameras()
            if cameras:
                await cam.initialize(cameras[0], "high")  # cameras[0] = rear
            else:
                raise RuntimeError("No se encontró cámara")
        except Exception as ex:
            self._state.camera_armed = False
            self._flet_camera = None
            self._layout.update_flet_camera(None)
            self._messages.show(f"Cámara no disponible: {ex}. Usando selector de archivos.", error=True)
            self._render()
            await self._pick_camera_image()

    async def _capture_and_detect(self, e) -> None:
        if self._flet_camera is None:
            return
        try:
            pic = await self._flet_camera.take_picture()
            if isinstance(pic, (bytes, bytearray)):
                _CAPTURE_PATH.write_bytes(pic)
            else:  # base64 string
                _CAPTURE_PATH.write_bytes(base64.b64decode(pic))
        except Exception as ex:
            self._messages.show(f"Error al capturar: {ex}", error=True)
            return
        self._state.camera_armed = False
        self._flet_camera = None
        self._layout.update_flet_camera(None)
        self._state.current_image = _CAPTURE_PATH
        self._controller.detect_health(e)

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
        tmp = Path(gettempdir()) / f"glycine_{f.name or 'upload.jpg'}"

        if f.bytes:
            tmp.write_bytes(f.bytes)
            self._controller.select_file(tmp)
        elif f.path and Path(f.path).exists():
            self._controller.select_file(Path(f.path))
