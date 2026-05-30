import os
from pathlib import Path

_PROJECT_ROOT = Path(__file__).parent.parent

test_folder = _PROJECT_ROOT / "Training" / "splits" / "test"
train_folder = _PROJECT_ROOT / "Training" / "splits" / "train"
source_dataset_folder = _PROJECT_ROOT / "Training" / "splits"
results_folder = _PROJECT_ROOT / "Training" / "outputs"

model_m1_path = _PROJECT_ROOT / "Models" / "model1.tflite"
model_m2_path = _PROJECT_ROOT / "Models" / "model2.tflite"

archivo_excel_salida_m1 = results_folder / "m1_results.xlsx"
archivo_excel_salida_m2 = results_folder / "m2_results.xlsx"

batch_size = 32
hash_threshold_hamming = 3
test_images_per_class_max = 100
train_images_per_class_max = 1000

disease_classes_m2 = ["bacterianas", "fungicas", "roya", "plagas_insectos", "virales"]
binary_classes_m1 = ["soya_sana", "soya_enferma"]

image_min_resolution = 224
image_required_channels = 3
random_seed = 42

disease_mapping = {
    "rust": "roya", "Rust": "roya", "ferrugen": "roya",
    "bacterial_blight": "bacterianas", "Bacterial": "bacterianas", "bacterial": "bacterianas",
    "fungal": "fungicas", "Fungal": "fungicas", "powdery": "fungicas",
    "insect": "plagas_insectos", "Caterpillar": "plagas_insectos", "Diabrotica": "plagas_insectos",
    "virus": "virales", "Virus": "virales", "Mossaic": "virales"
}

results_folder.mkdir(parents=True, exist_ok=True)
test_folder.mkdir(parents=True, exist_ok=True)
train_folder.mkdir(parents=True, exist_ok=True)


def validate_paths():
    if not source_dataset_folder.exists():
        raise FileNotFoundError(f"Source dataset folder not found: {source_dataset_folder}")
    if not model_m1_path.exists():
        raise FileNotFoundError(f"M1 model path not found: {model_m1_path}")
    if not model_m2_path.exists():
        raise FileNotFoundError(f"M2 model path not found: {model_m2_path}")
    return True
