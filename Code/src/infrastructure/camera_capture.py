from pathlib import Path
import threading
import time

import cv2


class CameraCaptureError(Exception):
    pass


class OpenCVCameraCapture:
    def __init__(self) -> None:
        self._cap = None
        self._stream_thread = None
        self._stop_stream = None
        self._current_frame = None
        self._frame_lock = threading.Lock()

    def _open_camera(self):
        backends: list[int] = []
        if hasattr(cv2, "CAP_DSHOW"):
            backends.append(cv2.CAP_DSHOW)
        if hasattr(cv2, "CAP_MSMF"):
            backends.append(cv2.CAP_MSMF)
        backends.append(cv2.CAP_ANY)

        for backend in backends:
            for index in (0, 1):
                cap = cv2.VideoCapture(index, backend)
                if cap.isOpened():
                    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
                    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
                    return cap
                cap.release()
        return None

    def start_session(self) -> None:
        if self._cap and self._cap.isOpened():
            return
        self._cap = self._open_camera()
        if not self._cap:
            raise CameraCaptureError("No se pudo abrir la camara.")

    def stop_session(self) -> None:
        self._stop_stream_thread()
        if self._cap:
            self._cap.release()
            self._cap = None

    def _stop_stream_thread(self) -> None:
        if self._stop_stream:
            self._stop_stream.set()
            if self._stream_thread and self._stream_thread.is_alive():
                self._stream_thread.join(timeout=1.0)
            self._stream_thread = None
            self._stop_stream = None

    def start_streaming(self, output_path: Path) -> None:
        if not self._cap or not self._cap.isOpened():
            self.start_session()
        
        self._stop_stream_thread()
        self._stop_stream = threading.Event()
        self._stream_thread = threading.Thread(
            target=self._stream_loop,
            args=(output_path, self._stop_stream),
            daemon=True
        )
        self._stream_thread.start()

    def _stream_loop(self, output_path: Path, stop_event: threading.Event) -> None:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        last_save_time = time.time()
        min_interval = 0.033
        
        while not stop_event.is_set():
            try:
                ok, frame = self._cap.read()
                if ok:
                    with self._frame_lock:
                        self._current_frame = frame
                    now = time.time()
                    if now - last_save_time >= min_interval:
                        cv2.imwrite(str(output_path), frame)
                        last_save_time = now
                else:
                    time.sleep(0.01)
            except Exception:
                time.sleep(0.01)

    def capture_current_frame(self, output_path: Path) -> Path:
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with self._frame_lock:
            if self._current_frame is not None:
                cv2.imwrite(str(output_path), self._current_frame)
                return output_path
        if self._cap and self._cap.isOpened():
            return self._read_to_file(self._cap, output_path, 8)
        raise CameraCaptureError("No se pudo capturar la imagen de la camara.")

    def capture_once(self, output_path: Path) -> Path:
        cap = self._open_camera()
        if not cap:
            raise CameraCaptureError("No se pudo abrir la camara.")
        try:
            return self._read_to_file(cap, output_path, 16)
        finally:
            cap.release()

    def _read_to_file(self, cap, output_path: Path, tries: int) -> Path:
        frame = None
        ok = False
        for _ in range(tries):
            ok, frame = cap.read()
            if ok:
                break
        if not ok:
            raise CameraCaptureError("No se pudo capturar la imagen de la camara.")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), frame)
        return output_path

