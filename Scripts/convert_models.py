import shutil
import sys
import io
from pathlib import Path

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

MODELS = [
    {
        "src": "Models/glycine-vision-hs",
        "dst": "Code/assets/models/hs",
        "tflite": "model.tflite",
    },
    {
        "src": "Models/glycine-vision-pd",
        "dst": "Code/assets/models/pd",
        "tflite": "model_unquant.tflite",
    },
]

def copy_models():
    for m in MODELS:
        src = Path(m["src"])
        dst = Path(m["dst"])
        dst.mkdir(parents=True, exist_ok=True)

        tflite_src = src / m["tflite"]
        tflite_dst = dst / m["tflite"]
        if tflite_src.exists():
            shutil.copy2(tflite_src, tflite_dst)
            print(f"  OK {tflite_dst}")
        else:
            print(f"  MISSING {tflite_src} — convert H5 first")

        labels_src = src / "labels.txt"
        labels_dst = dst / "labels.txt"
        if labels_src.exists():
            shutil.copy2(labels_src, labels_dst)
            print(f"  OK {labels_dst}")

if __name__ == "__main__":
    print("Copying TFLite models to Flutter assets...")
    copy_models()
    print("\nDone. Run inference_server.py for web, flutter build for mobile.")
