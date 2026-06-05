from typing import Optional
import cv2
import numpy as np
from config import HEALTH_GATE, ACTIVE_THRESHOLD, MAX_IMAGE_SIDE
from inference.classifier import (
    run_health,
    run_disease,
    probability_diseased,
    active_diseases,
)
from inference.leaf_analyzer import severity_hsv
from inference.model_registry import ModelRegistry
from inference.segmenter import run_segmentation
from services.climate import fetch_climate


class DiagnosisService:
    def __init__(self, registry: ModelRegistry):
        self._registry = registry

    def diagnose(self, image_bgr: np.ndarray, lat: Optional[float], lon: Optional[float]) -> dict:
        image_bgr = _resize_to_max(image_bgr)
        height, width = image_bgr.shape[:2]
        image_rgb = cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB)

        health_scores = run_health(self._registry.health, image_rgb)
        p_diseased = probability_diseased(health_scores, self._registry.health_labels)
        print(f"[diag] p_diseased={p_diseased:.3f}")

        zones, total_patches, leaf_patches = self._scan(image_bgr, image_rgb, p_diseased)
        findings = _aggregate_findings(zones, total_patches, leaf_patches)

        seg_result = run_segmentation(self._registry.segmenter, image_bgr) if (
            self._registry.segmenter and zones
        ) else None

        climate = fetch_climate(lat, lon) if lat is not None and lon is not None else None

        return {
            "zonas": zones,
            "enfermedades_detectadas": findings,
            "total_patches": total_patches,
            "leaf_patches": leaf_patches,
            "patch_size": MAX_IMAGE_SIDE,
            "image_width": width,
            "image_height": height,
            "seg_mask": seg_result["b64"] if seg_result else None,
            "global_severity_pct": seg_result["severity"] if seg_result else 0.0,
            "climate": climate,
        }

    def _scan(
        self,
        image_bgr: np.ndarray,
        image_rgb: np.ndarray,
        p_diseased: float,
    ) -> tuple[list[dict], int, int]:
        if p_diseased < HEALTH_GATE:
            return [], 1, 1

        disease_scores = run_disease(self._registry.disease, image_rgb)
        sev_pct, sev_lvl = severity_hsv(image_bgr)
        actives = active_diseases(
            disease_scores,
            self._registry.disease_labels,
            self._registry.disease_thresholds,
            sev_pct,
            ACTIVE_THRESHOLD,
        )
        if not actives:
            return [], 1, 1

        height, width = image_bgr.shape[:2]
        zone = {
            "bbox": [0, 0, width, height],
            "severidad_pct": sev_pct,
            "nivel": sev_lvl,
            "enfermedades": actives,
        }
        return [zone], 1, 1


def _resize_to_max(image: np.ndarray) -> np.ndarray:
    h, w = image.shape[:2]
    longest = max(h, w)
    if longest <= MAX_IMAGE_SIDE:
        return image
    scale = MAX_IMAGE_SIDE / longest
    return cv2.resize(image, (int(w * scale), int(h * scale)))


def _aggregate_findings(zones: list[dict], total: int, leaf: int) -> list[dict]:
    acc: dict[str, dict] = {}
    for zone in zones:
        for d in zone["enfermedades"]:
            entry = acc.setdefault(
                d["clase"],
                {"sev_sum": 0.0, "sev_max": 0.0, "prob_sum": 0.0, "count": 0},
            )
            entry["sev_sum"] += d["severidad_pct"]
            entry["sev_max"] = max(entry["sev_max"], d["severidad_pct"])
            entry["prob_sum"] += d["prob"]
            entry["count"] += 1
    denom = leaf if leaf > 0 else (total if total > 0 else 1)
    severity_order = ["minima", "leve", "moderada", "severa", "critica"]
    findings = []
    for clase, e in acc.items():
        n = e["count"]
        avg_sev = e["sev_sum"] / n
        findings.append({
            "clase": clase,
            "coverage_pct": round(n / denom * 100, 1),
            "avg_severidad_pct": round(avg_sev, 1),
            "max_severidad_pct": round(e["sev_max"], 1),
            "nivel": _level_from_pct(avg_sev),
            "avg_probability": round(e["prob_sum"] / n, 3),
            "zone_count": n,
        })
    findings.sort(
        key=lambda f: (severity_order.index(f["nivel"]), f["coverage_pct"]),
        reverse=True,
    )
    return findings


def _level_from_pct(pct: float) -> str:
    if pct < 5:
        return "minima"
    if pct < 15:
        return "leve"
    if pct < 35:
        return "moderada"
    if pct < 60:
        return "severa"
    return "critica"
