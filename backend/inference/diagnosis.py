import base64
from collections.abc import Callable

import cv2
import numpy as np

from inference.classifier import LeafClassifier
from inference.leaf_analyzer import SeverityAnalyzer
from inference.preprocessor import Preprocessor
from inference.segmenter import LeafSegmenter


class DiagnosisService:
    def __init__(
        self,
        segmenter: LeafSegmenter | None,
        health: LeafClassifier,
        disease: LeafClassifier,
        severity: SeverityAnalyzer,
        preprocessor: Preprocessor,
        climate_provider: Callable[[float, float], dict | None],
        health_gate: float,
        disease_confidence: float,
        max_image_side: int,
    ):
        self._segmenter = segmenter
        self._health = health
        self._disease = disease
        self._severity = severity
        self._pre = preprocessor
        self._climate = climate_provider
        self._gate = health_gate
        self._disease_confidence = disease_confidence
        self._max_side = max_image_side

    def diagnose(self, image_bgr: np.ndarray, lat: float | None, lon: float | None) -> dict:
        image_bgr = self._resize_to_max(image_bgr)
        height, width = image_bgr.shape[:2]
        norm = self._pre.normalize(cv2.cvtColor(image_bgr, cv2.COLOR_BGR2RGB))

        leaf = self._segmenter.segment(norm) if self._segmenter is not None else None
        if leaf is not None:
            leaf_full = cv2.resize(leaf, (width, height), interpolation=cv2.INTER_NEAREST)
            isolated = self._pre.isolate(norm, leaf_full)
        else:
            isolated = norm

        health_scores = self._health.predict(norm, isolated)
        p_diseased = self._health.probability_diseased(health_scores)

        findings: list[dict] = []
        mask3: np.ndarray | None = None
        severity = 0.0

        if leaf is not None and p_diseased >= self._gate:
            disease_scores = self._disease.predict(norm, isolated)
            detected = self._disease.top(disease_scores, self._disease_confidence)
            mask3, severity, components = self._severity.analyze(self._pre.to_mask_size(norm), leaf)
            if detected is not None:
                label, confidence = detected
                findings = [
                    {
                        "clase": label,
                        "coverage_pct": severity,
                        "avg_severidad_pct": severity,
                        "max_severidad_pct": severity,
                        "nivel": self._severity.level(severity),
                        "avg_probability": round(confidence, 3),
                        "zone_count": 1,
                        **components,
                    }
                ]
        elif leaf is not None:
            mask3 = leaf.astype(np.uint8)

        climate = self._climate(lat, lon) if lat is not None and lon is not None else None

        return {
            "zonas": [],
            "enfermedades_detectadas": findings,
            "total_patches": 1,
            "leaf_patches": 1,
            "patch_size": self._max_side,
            "image_width": width,
            "image_height": height,
            "seg_mask": self._encode(mask3) if mask3 is not None else None,
            "global_severity_pct": severity,
            "climate": climate,
        }

    def _resize_to_max(self, image: np.ndarray) -> np.ndarray:
        height, width = image.shape[:2]
        longest = max(height, width)
        if longest <= self._max_side:
            return image
        scale = self._max_side / longest
        return cv2.resize(image, (int(width * scale), int(height * scale)))

    @staticmethod
    def _encode(mask: np.ndarray) -> str:
        return base64.b64encode(mask.astype(np.uint8).flatten().tobytes()).decode("ascii")
