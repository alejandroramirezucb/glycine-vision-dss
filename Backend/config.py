import os
from pathlib import Path

_ROOT = Path(__file__).parent.parent
MODELS_DIR = Path(os.getenv("MODELS_DIR", str(_ROOT / "Models")))
MAX_IMAGE_SIDE = 400
HEALTH_GATE = 0.10
DISEASE_CONFIDENCE = 0.50
TFLITE_THREADS = max(2, os.cpu_count() or 4)
SPLITS_DIR = _ROOT / "Training" / "splits"
OUTPUTS_DIR = _ROOT / "Training" / "outputs"
BATCH_SIZE = 32
HASH_THRESHOLD = 3
TEST_IMAGES_MAX = 100
TRAIN_IMAGES_MAX = 1000
IMAGE_MIN_SIZE = 224
RANDOM_SEED = 42
DISEASE_CLASSES = ["bacterianas", "fungicas", "roya", "plagas_insectos", "virales"]
BINARY_CLASSES = ["soya_sana", "soya_enferma"]
DISEASE_MAPPING = {
    "rust": "roya", "Rust": "roya", "ferrugen": "roya",
    "bacterial_blight": "bacterianas", "Bacterial": "bacterianas", "bacterial": "bacterianas",
    "fungal": "fungicas", "Fungal": "fungicas", "powdery": "fungicas",
    "insect": "plagas_insectos", "Caterpillar": "plagas_insectos", "Diabrotica": "plagas_insectos",
    "virus": "virales", "Virus": "virales", "Mossaic": "virales",
}


def validate_paths() -> bool:
    if not SPLITS_DIR.exists():
        raise FileNotFoundError(f"Splits not found: {SPLITS_DIR}")
    health_model = MODELS_DIR / "health" / "model.tflite"
    if not health_model.exists():
        raise FileNotFoundError(f"Health model not found: {health_model}")
    return True
