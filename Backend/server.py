import tempfile
from pathlib import Path
from typing import Optional
import cv2
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware
from inference.diagnosis import DiagnosisService
from inference.model_registry import ModelRegistry

app = FastAPI(title="Glycine Vision Inference API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

_registry = ModelRegistry()
_service = DiagnosisService(_registry)

print("[ok] Health model:", _registry.health_labels)
print("[ok] Disease model:", _registry.disease_labels)
print(f"[ok] Segmenter: {'loaded' if _registry.segmenter else 'not available'}")


@app.post("/api/diagnose")
async def diagnose(
    image: UploadFile = File(...),
    lat: Optional[float] = Form(None),
    lon: Optional[float] = Form(None),
):
    payload = await image.read()
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(payload)
        tmp_path = tmp.name
    try:
        image_bgr = cv2.imread(tmp_path)
        if image_bgr is None:
            return {"error": "Unable to read image", "zonas": [], "enfermedades_detectadas": []}
        return _service.diagnose(image_bgr, lat, lon)
    finally:
        Path(tmp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
