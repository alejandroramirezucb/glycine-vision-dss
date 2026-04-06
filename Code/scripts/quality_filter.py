import hashlib
from pathlib import Path
from dataclasses import dataclass, field

import cv2

from config import MIN_RESOLUTION, HASH_THRESHOLD

try:
    from PIL import Image
    import imagehash
    _USE_PHASH = True
except ImportError:
    _USE_PHASH = False


@dataclass
class FilterStats:
    total: int = 0
    unreadable: int = 0
    low_resolution: int = 0
    grayscale: int = 0
    duplicate: int = 0
    approved: int = 0


def _compute_hash(filepath: Path):
    if _USE_PHASH:
        try:
            return imagehash.phash(Image.open(str(filepath)))
        except Exception:
            return None
    try:
        with open(filepath, "rb") as f:
            return hashlib.md5(f.read()).hexdigest()
    except Exception:
        return None


def _is_duplicate(h1, h2) -> bool:
    if h1 is None or h2 is None:
        return False
    if _USE_PHASH:
        return (h1 - h2) <= HASH_THRESHOLD
    return h1 == h2


def apply(images: list[Path], shared_hashes: dict) -> tuple[list[Path], FilterStats]:
    stats = FilterStats(total=len(images))
    approved = []

    for path in images:
        try:
            img = cv2.imread(str(path))
            if img is None:
                stats.unreadable += 1
                continue
        except Exception:
            stats.unreadable += 1
            continue

        h, w = img.shape[:2]
        if h < MIN_RESOLUTION or w < MIN_RESOLUTION:
            stats.low_resolution += 1
            continue

        if len(img.shape) != 3 or img.shape[2] != 3:
            stats.grayscale += 1
            continue

        img_hash = _compute_hash(path)
        if img_hash is not None:
            is_dup = any(_is_duplicate(img_hash, existing) for existing in shared_hashes.values())
            if is_dup:
                stats.duplicate += 1
                continue
            shared_hashes[str(path)] = img_hash

        approved.append(path)
        stats.approved += 1

    return approved, stats
