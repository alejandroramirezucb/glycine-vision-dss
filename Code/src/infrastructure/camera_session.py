from pathlib import Path
import cv2

class CameraCaptureError(Exception):
    pass

class CameraSession:
    def __init__(self) -> None:
        self._cap = None

    def open(self) -> None:
        if self._cap and self._cap.isOpened():
            return
        
        backends = []
        
        if hasattr(cv2, "CAP_DSHOW"):
            backends.append(cv2.CAP_DSHOW)
        if hasattr(cv2, "CAP_MSMF"):
            backends.append(cv2.CAP_MSMF)
       
        backends.append(cv2.CAP_ANY)
       
        for backend in backends:
            for index in (0, 1):
                cap = cv2.VideoCapture(index, backend)
                
                if cap.isOpened():
                    cap.set(cv2.CAP_PROP_FRAME_WIDTH, 640)
                    cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 480)
                    self._cap = cap
                    return
                
                cap.release()
        
        raise CameraCaptureError("No se pudo abrir la camara.")

    def close(self) -> None:
        if self._cap:
            self._cap.release()
            self._cap = None

    @property
    def cap(self):
        return self._cap

    @property
    def is_open(self) -> bool:
        return bool(self._cap and self._cap.isOpened())

    def read_to_file(self, output_path: Path, tries: int = 16) -> Path:
        frame, ok = None, False
        
        for _ in range(tries):
            ok, frame = self._cap.read()
            
            if ok:
                break
        
        if not ok:
            raise CameraCaptureError("No se pudo capturar la imagen de la camara.")
        
        output_path.parent.mkdir(parents=True, exist_ok=True)
        cv2.imwrite(str(output_path), frame)
        
        return output_path
