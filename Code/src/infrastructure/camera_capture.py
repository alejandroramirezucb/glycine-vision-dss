from collections.abc import Callable
from pathlib import Path
from infrastructure.camera_session import CameraSession, CameraCaptureError
from infrastructure.camera_stream import CameraStream


class OpenCVCameraCapture:
    def __init__(self) -> None:
        self._session = CameraSession()
        self._stream: CameraStream | None = None

    def start_session(self) -> None:
        self._session.open()

    def stop_session(self) -> None:
        if self._stream:
            self._stream.stop()
            self._stream = None
        
        self._session.close()

    def start_streaming(self, output_path: Path, on_frame_b64: Callable[[str], None] | None = None) -> None:
        if not self._session.is_open:
            self._session.open()
        if self._stream:
            self._stream.stop()
        
        self._stream = CameraStream(self._session.cap, on_frame=on_frame_b64)

    def get_current_b64(self) -> str | None:
        return self._stream.get_current_b64() if self._stream else None

    def capture_current_frame(self, output_path: Path) -> Path:
        b64 = self.get_current_b64()
        
        if b64:
            import base64
            output_path.parent.mkdir(parents=True, exist_ok=True)
            output_path.write_bytes(base64.b64decode(b64))
            return output_path
        if self._session.is_open:
            return self._session.read_to_file(output_path, tries=8)
        
        raise CameraCaptureError("No se pudo capturar la imagen de la camara.")

    def capture_once(self, output_path: Path) -> Path:
        session = CameraSession()
        session.open()
       
        try:
            return session.read_to_file(output_path)
        finally:
            session.close()
