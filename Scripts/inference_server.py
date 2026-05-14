from __future__ import annotations

import json
import os
import tempfile
import warnings
from pathlib import Path
from typing import Optional

import cv2
import numpy as np
import requests
import tensorflow as tf
from fastapi import FastAPI, File, Form, UploadFile
from fastapi.middleware.cors import CORSMiddleware

warnings.filterwarnings("ignore")

app = FastAPI()
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

PATCH_SIZE = 150
STRIDE = 100
MAX_SIDE = 400
HEALTH_GATE = 0.5
ACTIVE_THRESHOLD = 0.4
COVERAGE_MIN_PCT = 5.0
LEAF_GREEN_RATIO = 0.10
TFLITE_THREADS = max(2, os.cpu_count() or 4)

SEVERITY_ORDER = ["minima", "leve", "moderada", "severa", "critica"]
HSV_GREEN_LOW = np.array([20, 30, 30])
HSV_GREEN_HIGH = np.array([90, 255, 255])
HSV_LESION = [
    (np.array([10, 50, 20]), np.array([30, 255, 200])),
    (np.array([0, 50, 20]), np.array([10, 255, 180])),
]
HSV_NECROTIC = [(np.array([0, 0, 0]), np.array([180, 80, 60]))]


def load_tflite(path: str) -> tf.lite.Interpreter:
    interp = tf.lite.Interpreter(model_path=path, num_threads=TFLITE_THREADS)
    interp.allocate_tensors()
    return interp


def load_labels(path: str) -> list[str]:
    labels = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        stripped = line.strip()
        if not stripped:
            continue
        parts = stripped.split(" ", 1)
        labels.append(parts[1] if len(parts) == 2 and parts[0].isdigit() else stripped)
    return labels


def load_thresholds(path: str, labels: list[str]) -> dict[str, float]:
    file = Path(path)
    if not file.exists():
        return {label: 0.5 for label in labels}
    raw = json.loads(file.read_text(encoding="utf-8"))
    return {label: float(raw.get(label, 0.5)) for label in labels}


try:
    health_interp = load_tflite("Models/glycine-vision-hs/model.tflite")
    health_labels = load_labels("Models/glycine-vision-hs/labels.txt")
    print("[ok] Health model loaded:", health_labels)
except Exception as exc:
    health_interp = None
    health_labels = []
    print(f"[err] Health model load failed: {exc}")

try:
    disease_path = "Models/glycine-vision-pd/model.tflite"
    if not Path(disease_path).exists():
        disease_path = "Models/glycine-vision-pd/model_unquant.tflite"
    disease_interp = load_tflite(disease_path)
    disease_labels = load_labels("Models/glycine-vision-pd/labels.txt")
    disease_thresholds = load_thresholds(
        "Models/glycine-vision-pd/thresholds.json",
        disease_labels,
    )
    print(f"[ok] Disease model loaded from {disease_path}:", disease_labels)
    print("[ok] Thresholds:", disease_thresholds)
except Exception as exc:
    disease_interp = None
    disease_labels = []
    disease_thresholds = {}
    print(f"[err] Disease model load failed: {exc}")


def preprocess_single(rgb_array: np.ndarray, dtype, target_hw: tuple[int, int]) -> np.ndarray:
    resized = cv2.resize(rgb_array, (target_hw[1], target_hw[0]))
    if dtype == np.float32:
        return resized.astype(np.float32)
    return resized.astype(dtype)


def batch_run(interp: tf.lite.Interpreter, patches_rgb: np.ndarray) -> np.ndarray:
    n = patches_rgb.shape[0]
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    target_shape = list(inp["shape"])
    target_h, target_w = int(target_shape[1]), int(target_shape[2])
    if target_shape[0] != n:
        target_shape[0] = n
        interp.resize_tensor_input(inp["index"], target_shape)
        interp.allocate_tensors()
        inp = interp.get_input_details()[0]
        out = interp.get_output_details()[0]
    batch = np.stack([
        preprocess_single(p, inp["dtype"], (target_h, target_w))
        for p in patches_rgb
    ])
    interp.set_tensor(inp["index"], batch)
    interp.invoke()
    raw = interp.get_tensor(out["index"])
    if out["dtype"] == np.uint8:
        return raw.astype(np.float32) / 255.0
    return raw.astype(np.float32)


def is_likely_leaf(patch_bgr: np.ndarray) -> bool:
    hsv = cv2.cvtColor(patch_bgr, cv2.COLOR_BGR2HSV)
    green = cv2.inRange(hsv, HSV_GREEN_LOW, HSV_GREEN_HIGH)
    pixels = patch_bgr.shape[0] * patch_bgr.shape[1]
    return cv2.countNonZero(green) > pixels * LEAF_GREEN_RATIO


def severity_hsv(patch_bgr: np.ndarray) -> tuple[float, str]:
    hsv = cv2.cvtColor(patch_bgr, cv2.COLOR_BGR2HSV)
    mask_healthy = cv2.inRange(hsv, HSV_GREEN_LOW, HSV_GREEN_HIGH)
    mask_lesion = _mask_from_ranges(hsv, HSV_LESION)
    mask_necrotic = _mask_from_ranges(hsv, HSV_NECROTIC)
    mask_disease = cv2.bitwise_or(mask_lesion, mask_necrotic)
    kernel = np.ones((3, 3), np.uint8)
    mask_disease = cv2.morphologyEx(mask_disease, cv2.MORPH_OPEN, kernel)
    mask_disease = cv2.morphologyEx(mask_disease, cv2.MORPH_CLOSE, kernel)
    mask_leaf = cv2.bitwise_or(mask_healthy, mask_disease)
    total_pixels = patch_bgr.shape[0] * patch_bgr.shape[1]
    leaf_pixels = int(cv2.countNonZero(mask_leaf))
    diseased_pixels = int(cv2.countNonZero(mask_disease))
    if leaf_pixels < total_pixels * 0.1:
        return 0.0, "minima"
    pct = round(min(diseased_pixels / leaf_pixels * 100, 100.0), 1)
    return pct, _severity_level(pct)


def _mask_from_ranges(hsv: np.ndarray, ranges) -> np.ndarray:
    mask = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in ranges:
        mask = cv2.bitwise_or(mask, cv2.inRange(hsv, low, high))
    return mask


def _severity_level(pct: float) -> str:
    if pct < 5:
        return "minima"
    if pct < 15:
        return "leve"
    if pct < 35:
        return "moderada"
    if pct < 60:
        return "severa"
    return "critica"


def expand_binary(scores: np.ndarray, num_labels: int) -> np.ndarray:
    if scores.ndim == 1 and scores.shape[0] == 1 and num_labels == 2:
        return np.array([1.0 - scores[0], scores[0]], dtype=np.float32)
    if scores.ndim == 2 and scores.shape[1] == 1 and num_labels == 2:
        return np.concatenate([1.0 - scores, scores], axis=1)
    return scores


def probability_diseased(scores: np.ndarray, labels: list[str]) -> float:
    expanded = expand_binary(scores, len(labels))
    for i, label in enumerate(labels):
        if "enferm" in label.lower() or "diseased" in label.lower():
            return float(expanded[i])
    return float(expanded[-1])


def active_diseases(scores: np.ndarray, severity_pct: float) -> list[dict]:
    hits = []
    for i, label in enumerate(disease_labels):
        threshold = min(disease_thresholds.get(label, 0.5), ACTIVE_THRESHOLD)
        if scores[i] >= threshold:
            hits.append((label, float(scores[i])))
    if not hits:
        return []
    total = sum(p for _, p in hits)
    return [
        {
            "clase": label,
            "prob": round(prob, 3),
            "severidad_pct": round(severity_pct * prob / total, 1),
        }
        for label, prob in hits
    ]


def fetch_climate(lat: float, lon: float) -> Optional[dict]:
    try:
        response = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,precipitation,dew_point_2m",
                "timezone": "auto",
            },
            timeout=5,
        )
        response.raise_for_status()
        current = response.json().get("current", {})
        return {
            "temp_c": float(current.get("temperature_2m", 0)),
            "humidity": float(current.get("relative_humidity_2m", 0)),
            "precip_mm": float(current.get("precipitation", 0)),
            "dewpoint_c": float(current.get("dew_point_2m", 0)),
        }
    except Exception:
        return None


def scan_image(image_bgr: np.ndarray) -> tuple[list[dict], int]:
    if health_interp is None or disease_interp is None:
        return [], 0
    height, width = image_bgr.shape[:2]
    candidates = []
    total_patches = 0
    for y in range(0, height - PATCH_SIZE + 1, STRIDE):
        for x in range(0, width - PATCH_SIZE + 1, STRIDE):
            total_patches += 1
            patch_bgr = image_bgr[y:y + PATCH_SIZE, x:x + PATCH_SIZE]
            if not is_likely_leaf(patch_bgr):
                continue
            patch_rgb = cv2.cvtColor(patch_bgr, cv2.COLOR_BGR2RGB)
            candidates.append((x, y, patch_bgr, patch_rgb))

    if not candidates:
        return [], total_patches

    patches_rgb = np.stack([c[3] for c in candidates])
    health_scores = batch_run(health_interp, patches_rgb)
    diseased_idx = [
        i for i in range(len(candidates))
        if probability_diseased(health_scores[i], health_labels) >= HEALTH_GATE
    ]
    if not diseased_idx:
        return [], total_patches

    diseased_patches = patches_rgb[diseased_idx]
    disease_scores = batch_run(disease_interp, diseased_patches)

    zones = []
    for j, idx in enumerate(diseased_idx):
        x, y, patch_bgr, _ = candidates[idx]
        sev_pct, sev_lvl = severity_hsv(patch_bgr)
        if sev_pct < 2.0:
            continue
        actives = active_diseases(disease_scores[j], sev_pct)
        if not actives:
            continue
        zones.append({
            "bbox": [x, y, x + PATCH_SIZE, y + PATCH_SIZE],
            "severidad_pct": sev_pct,
            "nivel": sev_lvl,
            "enfermedades": actives,
        })
    return zones, total_patches


def aggregate_findings(zones: list[dict], total_patches: int) -> list[dict]:
    accumulators: dict[str, dict] = {}
    for zone in zones:
        for disease in zone["enfermedades"]:
            entry = accumulators.setdefault(
                disease["clase"],
                {"sev_sum": 0.0, "sev_max": 0.0, "prob_sum": 0.0, "count": 0},
            )
            entry["sev_sum"] += disease["severidad_pct"]
            entry["sev_max"] = max(entry["sev_max"], disease["severidad_pct"])
            entry["prob_sum"] += disease["prob"]
            entry["count"] += 1
    findings = []
    for clase, acc in accumulators.items():
        count = acc["count"]
        avg_sev = acc["sev_sum"] / count
        findings.append({
            "clase": clase,
            "coverage_pct": round(count / total_patches * 100, 1) if total_patches else 0.0,
            "avg_severidad_pct": round(avg_sev, 1),
            "max_severidad_pct": round(acc["sev_max"], 1),
            "nivel": _severity_level(avg_sev),
            "avg_probability": round(acc["prob_sum"] / count, 3),
            "zone_count": count,
        })
    findings.sort(
        key=lambda f: (SEVERITY_ORDER.index(f["nivel"]), f["coverage_pct"]),
        reverse=True,
    )
    return findings


def resize_to_max(image_bgr: np.ndarray) -> np.ndarray:
    height, width = image_bgr.shape[:2]
    longest = max(height, width)
    if longest <= MAX_SIDE:
        return image_bgr
    scale = MAX_SIDE / longest
    return cv2.resize(image_bgr, (int(width * scale), int(height * scale)))


@app.post("/api/diagnose")
async def diagnose(
    image: UploadFile = File(...),
    lat: Optional[float] = Form(None),
    lon: Optional[float] = Form(None),
):
    if health_interp is None or disease_interp is None:
        return {"error": "Models not loaded"}

    payload = await image.read()
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(payload)
        tmp_path = tmp.name
    try:
        image_bgr = cv2.imread(tmp_path)
        if image_bgr is None:
            return {"error": "Unable to read image"}
        image_bgr = resize_to_max(image_bgr)
        height, width = image_bgr.shape[:2]
        zones, total_patches = scan_image(image_bgr)
        findings = aggregate_findings(zones, total_patches)
        climate = fetch_climate(lat, lon) if lat is not None and lon is not None else None
        return {
            "zonas": zones,
            "enfermedades_detectadas": findings,
            "total_patches": total_patches,
            "patch_size": PATCH_SIZE,
            "image_width": width,
            "image_height": height,
            "climate": climate,
        }
    finally:
        Path(tmp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8001)
