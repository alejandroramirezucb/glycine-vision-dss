import os
from pathlib import Path

_ROOT = Path(__file__).parent.parent
MODELS_DIR = Path(os.getenv("MODELS_DIR", str(_ROOT / "models")))
MAX_IMAGE_SIDE = 400
HEALTH_GATE = 0.5
DISEASE_CONFIDENCE = 0.50
TFLITE_THREADS = max(2, os.cpu_count() or 4)
MAX_UPLOAD_BYTES = int(os.getenv("MAX_UPLOAD_BYTES", str(10 * 1024 * 1024)))
CORS_ORIGINS = [origin.strip() for origin in os.getenv("CORS_ORIGINS", "").split(",") if origin.strip()]
