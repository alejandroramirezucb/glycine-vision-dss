import base64
import threading
import time
from collections.abc import Callable
import cv2


class CameraStream:
    def __init__(self, cap, on_frame: Callable[[str], None] | None = None) -> None:
        self._cap = cap
        self._on_frame = on_frame
        self._current_b64: str | None = None
        self._lock = threading.Lock()
        self._stop_event = threading.Event()
        self._thread = threading.Thread(target=self._loop, daemon=True)
        self._thread.start()

    def stop(self) -> None:
        self._stop_event.set()
        self._thread.join(timeout=1.0)

    def get_current_b64(self) -> str | None:
        with self._lock:
            return self._current_b64

    def _loop(self) -> None:
        last_save = 0.0
        min_interval = 0.03
        
        while not self._stop_event.is_set():
            try:
                ok, frame = self._cap.read()
                
                if not ok:
                    time.sleep(0.01)
                    continue
                
                now = time.time()
                
                if now - last_save < min_interval:
                    time.sleep(0.005)
                    continue
                
                last_save = now
                frame = cv2.resize(frame, (480, 270), interpolation=cv2.INTER_AREA)
                _, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 45])
                b64 = base64.b64encode(buf).decode()
                
                with self._lock:
                    self._current_b64 = b64
                
                if self._on_frame:
                    self._on_frame(b64)
            except Exception:
                time.sleep(0.01)
