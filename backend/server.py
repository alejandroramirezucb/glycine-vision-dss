import cv2
import numpy as np
from fastapi import FastAPI, File, Form, HTTPException, UploadFile
from fastapi.middleware.cors import CORSMiddleware

from config import CORS_ORIGINS, DISEASE_CONFIDENCE, HEALTH_GATE, MAX_IMAGE_SIDE, MAX_UPLOAD_BYTES
from inference.diagnosis import DiagnosisService
from inference.leaf_analyzer import SeverityAnalyzer
from inference.model_registry import ModelRegistry
from inference.preprocessor import Preprocessor
from services.climate import fetch_climate

app = FastAPI(title="Glycine Vision Inference API")
app.add_middleware(
    CORSMiddleware,
    allow_origins=CORS_ORIGINS,
    allow_origin_regex=None if CORS_ORIGINS else r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
    allow_methods=["POST"],
    allow_headers=["*"],
)

_registry = ModelRegistry()
_service = DiagnosisService(
    segmenter=_registry.segmenter,
    health=_registry.health,
    disease=_registry.disease,
    severity=SeverityAnalyzer(),
    preprocessor=Preprocessor(),
    climate_provider=fetch_climate,
    health_gate=HEALTH_GATE,
    disease_confidence=DISEASE_CONFIDENCE,
    max_image_side=MAX_IMAGE_SIDE,
)

print("[ok] Health model:", _registry.health.labels)
print("[ok] Disease model:", _registry.disease.labels)
print(f"[ok] Segmenter: {'loaded' if _registry.segmenter else 'not available'}")


@app.post("/api/diagnose")
async def diagnose(
    image: UploadFile = File(...),
    lat: float | None = Form(None),
    lon: float | None = Form(None),
):
    payload = await image.read()
    if len(payload) > MAX_UPLOAD_BYTES:
        raise HTTPException(status_code=413, detail="Image too large")
    image_bgr = cv2.imdecode(np.frombuffer(payload, np.uint8), cv2.IMREAD_COLOR)
    if image_bgr is None:
        raise HTTPException(status_code=415, detail="Unsupported media type")
    coarse_lat = round(lat, 2) if lat is not None else None
    coarse_lon = round(lon, 2) if lon is not None else None
    try:
        return _service.diagnose(image_bgr, coarse_lat, coarse_lon)
    except Exception as error:
        raise HTTPException(status_code=500, detail="Diagnosis failed") from error


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
