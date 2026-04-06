from pathlib import Path
from config import VALID_EXTENSIONS


def scan(directory: Path) -> list[Path]:
    if not directory.exists():
        return []
    found = []
    for ext in VALID_EXTENSIONS:
        found.extend(directory.rglob(f"*{ext}"))
        found.extend(directory.rglob(f"*{ext.upper()}"))
    seen = set()
    unique = []
    for path in found:
        key = str(path).lower()
        if key not in seen:
            seen.add(key)
            unique.append(path)
    return sorted(unique)
