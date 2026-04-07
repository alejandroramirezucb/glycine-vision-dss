from pathlib import Path
import threading
import time

import flet as ft

from application.use_cases import PredictDiseaseTypeUseCase, PredictSoyHealthUseCase
from infrastructure.camera_capture import OpenCVCameraCapture
from presentation.diagnosis_controller import DiagnosisController
from presentation.layout_factory import LayoutFactory
from presentation.screen_factory import ScreenFactory
from presentation.ui_messages import SnackbarService
from presentation.view_state import AppState


class SoyDiagnosisApp:
	def __init__(self, page: ft.Page, health_use_case: PredictSoyHealthUseCase, disease_use_case: PredictDiseaseTypeUseCase, camera_capture: OpenCVCameraCapture) -> None:
		self._page = page
		self._phone_width = 390
		self._state = AppState()
		self._layout = LayoutFactory()
		self._screens = ScreenFactory(self._layout)
		self._controller = DiagnosisController(self._state, health_use_case, disease_use_case, camera_capture, SnackbarService(page))
		self._controller.bind(self._render)
		self._file_picker = ft.FilePicker()
		self._page.services.append(self._file_picker)
		self._update_thread = None
		self._stop_update = False

	def run(self) -> None:
		self._page.title = "Glycine Vision DSS"
		self._page.padding = 0
		self._page.bgcolor = "#d9dcdf"
		if hasattr(self._page, "window") and self._page.window:
			self._page.window.width = 412
			self._page.window.height = 915
			self._page.window.min_width = 412
			self._page.window.max_width = 412
			self._page.window.min_height = 915
			self._page.window.max_height = 915
			self._page.window.resizable = False
		else:
			self._page.window_width = 412
			self._page.window_height = 915
			self._page.window_resizable = False
		self._page.spacing = 0
		self._start_update_thread()
		self._render()

	def _start_update_thread(self) -> None:
		if self._update_thread and self._update_thread.is_alive():
			return
		self._stop_update = False
		self._update_thread = threading.Thread(target=self._update_loop, daemon=True)
		self._update_thread.start()

	def _update_loop(self) -> None:
		while not self._stop_update:
			try:
				if self._state.camera_armed:
					self._render()
				time.sleep(0.05)
			except Exception:
				time.sleep(0.05)

	def _stop_update_thread(self) -> None:
		self._stop_update = True
		if self._update_thread and self._update_thread.is_alive():
			self._update_thread.join(timeout=1.0)

	def _render(self) -> None:
		self._page.clean()
		phone_shell = ft.Container(
			width=self._phone_width,
			padding=10,
			content=ft.Column(
				controls=[
					self._layout.build_header(self._state.can_go_back, self._controller.go_home, self._controller.go_back),
					self._build_screen(),
				],
				expand=True,
				spacing=12,
			),
		)
		self._page.add(ft.Row(controls=[phone_shell], alignment=ft.MainAxisAlignment.CENTER))
		self._page.update()

	def _build_screen(self) -> ft.Control:
		return self._screens.build_by_state(self._state, self._pick_image, self._controller.capture, self._controller.detect_health, self._controller.detect_disease)

	async def _pick_image(self, _: ft.ControlEvent) -> None:
		files = await self._file_picker.pick_files(allow_multiple=False, allowed_extensions=["png", "jpg", "jpeg", "bmp", "webp", "tif", "tiff"])
		if files and files[0].path:
			self._controller.select_file(Path(files[0].path))

