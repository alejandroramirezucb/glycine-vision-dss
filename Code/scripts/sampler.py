import random
from pathlib import Path
from collections import defaultdict

from config import RANDOM_SEED


def classify_by_source(paths: list[Path], folder_names: list[str]) -> dict[str, list[Path]]:
    by_source = defaultdict(list)
    for path in paths:
        path_str = str(path)
        matched = None
        for folder in folder_names:
            if f"\\{folder}\\" in path_str or f"/{folder}/" in path_str:
                matched = folder
                break
        by_source[matched or "_unclassified"].append(path)
    return dict(by_source)


def sample(by_source: dict[str, list[Path]], target: int, seed: int = RANDOM_SEED) -> tuple[list[Path], dict[str, int]]:
    random.seed(seed)
    sources = {k: v for k, v in by_source.items() if k != "_unclassified" and v}
    available = sum(len(v) for v in sources.values())

    if available == 0:
        return [], {}

    if available <= target:
        selected = [p for paths in sources.values() for p in paths]
        random.shuffle(selected)
        return selected, {k: len(v) for k, v in sources.items()}

    quotas = {
        src: min(int(round(len(paths) / available * target)), len(paths))
        for src, paths in sources.items()
    }

    diff = target - sum(quotas.values())
    for src in sorted(quotas, key=lambda k: len(sources[k]), reverse=True):
        if diff == 0:
            break
        if diff > 0:
            add = min(diff, len(sources[src]) - quotas[src])
            quotas[src] += add
            diff -= add
        elif diff < 0:
            sub = min(-diff, quotas[src])
            quotas[src] -= sub
            diff += sub

    selected = []
    breakdown = {}
    for src, quota in quotas.items():
        picked = random.sample(sources[src], quota)
        selected.extend(picked)
        breakdown[src] = quota

    random.shuffle(selected)
    return selected, breakdown
