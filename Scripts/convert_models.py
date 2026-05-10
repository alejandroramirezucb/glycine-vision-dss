import shutil
from pathlib import Path
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

MODELS = [
    ("Models/glycine-vision-hs", "Code/assets/models/hs"),
    ("Models/glycine-vision-pd", "Code/assets/models/pd"),
]

DATA = []

def copy_keras_models():
    for src_dir, dst_dir in MODELS:
        print(f"Copying {src_dir} -> {dst_dir}")
        src = Path(src_dir)
        dst = Path(dst_dir)
        dst.parent.mkdir(parents=True, exist_ok=True)
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
        print(f"  OK {dst_dir}")

def copy_data():
    for src, dst in DATA:
        print(f"Copying {src} -> {dst}")
        Path(dst).parent.mkdir(parents=True, exist_ok=True)
        Path(dst).write_text(Path(src).read_text())
        print(f"  OK {dst}")

if __name__ == "__main__":
    print("Copying Keras H5 models to App assets...")
    copy_keras_models()
    if DATA:
        print("\nCopying treatment data...")
        copy_data()
    print("\nDone! Models ready. Run inference_server.py for web, APK/IPA for mobile.")
