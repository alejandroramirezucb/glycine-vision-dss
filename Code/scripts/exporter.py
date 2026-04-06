import shutil
from pathlib import Path
from datetime import datetime

from config import SOURCE_LABELS, RANDOM_SEED


def copy_images(paths: list[Path], destination: Path, prefix: str) -> tuple[int, int]:
    destination.mkdir(parents=True, exist_ok=True)
    copied, errors = 0, 0
    for i, path in enumerate(paths, 1):
        ext = path.suffix.lower() or ".jpg"
        try:
            shutil.copy2(str(path), str(destination / f"{prefix}_{i:04d}{ext}"))
            copied += 1
        except Exception:
            errors += 1
    return copied, errors


def write_approved_list(paths: list[Path], filepath: Path, header: str):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(f"# {header}: {len(paths)}\n# {timestamp}\n\n")
        for p in sorted(paths):
            f.write(f"{p}\n")


def write_traceability(group: str, selected: list[Path], breakdown: dict[str, int], destination: Path):
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    filepath = destination / f"{group}_trazabilidad.txt"
    with open(filepath, "w", encoding="utf-8") as f:
        f.write(f"# {group} - Trazabilidad\n# {timestamp}\n")
        f.write(f"# Metodo: muestreo estratificado proporcional\n")
        f.write(f"# Semilla: {RANDOM_SEED}\n# Total: {len(selected)}\n\n")
        for src, count in sorted(breakdown.items()):
            label = SOURCE_LABELS.get(src, "?")
            f.write(f"# {src} ({label}): {count}\n")
        f.write("\n")
        for path in selected:
            f.write(f"{path}\n")
