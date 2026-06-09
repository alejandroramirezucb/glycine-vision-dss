import base64
from typing import Optional

import cv2
import numpy as np

from config import DISEASE_CONFIDENCE, HEALTH_GATE, MAX_IMAGE_SIDE
from inference.classifier import (
    run_health,
    run_disease,
    probability_diseased,
    top_disease,
)
from inference.leaf_analyzer import analyze_leaf, level_from_pct
from inference.model_registry import ModelRegistry
from inference.segmenter import segment_leaf, shades_of_gray
from services.climate import fetch_climate

_MASK_SIZE = 256


class DiagnosisService:
    def __init__(self, registry: ModelRegistry):
        self._registry = registry

    def diagnose(self, image_bgr: np.ndarray, lat: Optional[float], lon: Optional[float]) -> dict:
        image_bgr = _resize_to_max(image_bgr)
        height, width = image_bgr.shape[:2]
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

        health_scores = run_health(self._registry.health, image_rgb)
        p_diseased = probability_diseased(health_scores, self._registry.health_labels)

        leaf = segment_leaf(self._registry.segmenter, image_bgr) if self._registry.segmenter else None
        findings: list[dict] = []
        mask3: Optional[np.ndarray] = None
        severity = 0.0

        if leaf is not None and p_diseased >= HEALTH_GATE:
            leaf_full = cv2.resize(leaf, (width, height), interpolation=cv2.INTER_NEAREST)
            clean_rgb = image_rgb.copy()
            clean_rgb[leaf_full == 0] = 0
            disease_scores = run_disease(self._registry.disease, clean_rgb)
            detected = top_disease(disease_scores, self._registry.disease_labels, DISEASE_CONFIDENCE)

            norm256 = shades_of_gray(cv2.resize(image_rgb, (_MASK_SIZE, _MASK_SIZE)))
            mask3, severity, components = analyze_leaf(norm256, leaf)

            if detected is not None:
                label, confidence = detected
                findings = [{
                    "clase": label,
                    "coverage_pct": severity,
                    "avg_severidad_pct": severity,
                    "max_severidad_pct": severity,
                    "nivel": level_from_pct(severity),
                    "avg_probability": round(confidence, 3),
                    "zone_count": 1,
                    **components,
                }]
        elif leaf is not None:
            mask3 = leaf.astype(np.uint8)

        climate = fetch_climate(lat, lon) if lat is not None and lon is not None else None

        return {
            "zonas": [],
            "enfermedades_detectadas": findings,
            "total_patches": 1,
            "leaf_patches": 1,
            "patch_size": MAX_IMAGE_SIDE,
            "image_width": width,
            "image_height": height,
            "seg_mask": _encode(mask3) if mask3 is not None else None,
            "global_severity_pct": severity,
            "climate": climate,
        }


def _encode(mask: np.ndarray) -> str:
    return base64.b64encode(mask.astype(np.uint8).flatten().tobytes()).decode("ascii")


def _resize_to_max(image: np.ndarray) -> np.ndarray:
    h, w = image.shape[:2]
    longest = max(h, w)
    if longest <= MAX_IMAGE_SIDE:
        return image
    scale = MAX_IMAGE_SIDE / longest
    return cv2.resize(image, (int(w * scale), int(h * scale)))
