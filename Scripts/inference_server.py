from fastapi import FastAPI, UploadFile, File, Form
from fastapi.middleware.cors import CORSMiddleware
import tempfile
from pathlib import Path
from typing import Optional
import warnings

import numpy as np
from PIL import Image
import cv2
import tensorflow as tf
import requests

warnings.filterwarnings("ignore")

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])


def load_tflite(path):
    interp = tf.lite.Interpreter(model_path=str(path))
    interp.allocate_tensors()
    return interp


def load_labels(path):
    labels = []
    for line in Path(path).read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(" ", 1)
        labels.append(parts[1] if len(parts) == 2 and parts[0].isdigit() else line)
    return labels


try:
    health_interp = load_tflite("Models/glycine-vision-hs/model.tflite")
    health_labels = load_labels("Models/glycine-vision-hs/labels.txt")
    print("[ok] Health model loaded:", health_labels)
except Exception as e:
    health_interp = None
    health_labels = []
    print(f"Health model load failed: {e}")

try:
    disease_interp = load_tflite("Models/glycine-vision-pd/model_unquant.tflite")
    disease_labels = load_labels("Models/glycine-vision-pd/labels.txt")
    print("[ok] Disease model loaded:", disease_labels)
except Exception as e:
    disease_interp = None
    disease_labels = []
    print(f"Disease model load failed: {e}")


def preprocess(image_path_or_array, dtype):
    if isinstance(image_path_or_array, np.ndarray):
        img = Image.fromarray(image_path_or_array).resize((224, 224))
    else:
        img = Image.open(image_path_or_array).convert("RGB").resize((224, 224))
    arr = np.array(img)
    if dtype == np.float32:
        arr = arr.astype(np.float32) / 127.5 - 1.0
    else:
        arr = arr.astype(dtype)
    return np.expand_dims(arr, 0)


def run_tflite_from_path(interp, image_path):
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    interp.set_tensor(inp["index"], preprocess(image_path, inp["dtype"]))
    interp.invoke()
    raw = interp.get_tensor(out["index"])[0]
    if out["dtype"] == np.uint8:
        return raw.astype(np.float32) / 255.0
    return raw.astype(np.float32)


def run_tflite_from_array(interp, rgb_array):
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    interp.set_tensor(inp["index"], preprocess(rgb_array, inp["dtype"]))
    interp.invoke()
    raw = interp.get_tensor(out["index"])[0]
    if out["dtype"] == np.uint8:
        return raw.astype(np.float32) / 255.0
    return raw.astype(np.float32)


def classify(interp, labels, file_bytes):
    if interp is None:
        return {"error": "Model not loaded"}
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name
    try:
        scores = run_tflite_from_path(interp, tmp_path)
        results = [{"label": labels[i], "confidence": float(scores[i])} for i in range(len(labels))]
        results.sort(key=lambda x: x["confidence"], reverse=True)
        return {"predictions": results}
    finally:
        Path(tmp_path).unlink(missing_ok=True)


@app.post("/api/classify/health")
async def classify_health(file: UploadFile = File(...)):
    return classify(health_interp, health_labels, await file.read())


@app.post("/api/classify/disease")
async def classify_disease(file: UploadFile = File(...)):
    return classify(disease_interp, disease_labels, await file.read())


RANGO_VERDE = [(np.array([30, 40, 40]), np.array([85, 255, 255]))]
RANGO_LESION = [
    (np.array([10, 50, 20]), np.array([30, 255, 200])),
    (np.array([0, 50, 20]), np.array([10, 255, 180])),
]
RANGO_NECRO = [(np.array([0, 0, 0]), np.array([180, 80, 60]))]


def severity_hsv(patch_bgr):
    hsv = cv2.cvtColor(patch_bgr, cv2.COLOR_BGR2HSV)
    mask_sana = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_VERDE:
        mask_sana = cv2.bitwise_or(mask_sana, cv2.inRange(hsv, low, high))
    mask_les = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_LESION:
        mask_les = cv2.bitwise_or(mask_les, cv2.inRange(hsv, low, high))
    mask_nec = np.zeros(hsv.shape[:2], dtype=np.uint8)
    for low, high in RANGO_NECRO:
        mask_nec = cv2.bitwise_or(mask_nec, cv2.inRange(hsv, low, high))
    mask_enf = cv2.bitwise_or(mask_les, mask_nec)
    kernel = np.ones((3, 3), np.uint8)
    mask_enf = cv2.morphologyEx(mask_enf, cv2.MORPH_OPEN, kernel)
    mask_enf = cv2.morphologyEx(mask_enf, cv2.MORPH_CLOSE, kernel)
    mask_hoja = cv2.bitwise_or(mask_sana, mask_enf)

    px_total = patch_bgr.shape[0] * patch_bgr.shape[1]
    px_hoja = int(cv2.countNonZero(mask_hoja))
    px_enf = int(cv2.countNonZero(mask_enf))

    if px_hoja > px_total * 0.1:
        pct = (px_enf / px_hoja) * 100
    else:
        pct = 0.0
    pct = min(pct, 100.0)
    pct = round(pct, 1)

    if pct < 5:
        nivel, urg = "minima", "Solo monitoreo preventivo"
    elif pct < 15:
        nivel, urg = "leve", "Aplicacion preventiva recomendada"
    elif pct < 35:
        nivel, urg = "moderada", "Tratamiento necesario en 48-72 horas"
    elif pct < 60:
        nivel, urg = "severa", "Tratamiento urgente"
    else:
        nivel, urg = "critica", "Emergencia fitosanitaria"
    return pct, nivel, urg


ONSET_TABLE = {
    "roya": {"minima": (2, 5), "leve": (5, 10), "moderada": (10, 18), "severa": (18, 28), "critica": (28, 45)},
    "fungicas": {"minima": (3, 7), "leve": (7, 14), "moderada": (14, 21), "severa": (21, 35), "critica": (35, 55)},
    "bacterianas": {"minima": (2, 6), "leve": (6, 12), "moderada": (12, 20), "severa": (20, 30), "critica": (30, 45)},
    "virales": {"minima": (5, 10), "leve": (10, 18), "moderada": (18, 30), "severa": (30, 45), "critica": (45, 70)},
    "plagas_insectos": {"minima": (1, 3), "leve": (3, 7), "moderada": (7, 14), "severa": (14, 21), "critica": (21, 35)},
}


def estimar_onset(clase, nivel, clima):
    tabla = ONSET_TABLE.get(clase)
    if not tabla or nivel not in tabla:
        return None
    minD, maxD = tabla[nivel]
    base = f"Rango base {clase}/{nivel}: {minD}-{maxD} dias"
    if clima is None:
        return {"min_days": minD, "max_days": maxD, "explanation": base + " (sin clima)"}

    factor = 1.0
    notes = []
    t, h, p = clima["temp_c"], clima["humidity"], clima["precip_mm"]
    if clase == "roya":
        if h > 80 and 20 <= t <= 28:
            factor = 0.7
            notes.append("clima favorable acelera onset")
        elif h < 50:
            factor = 1.3
            notes.append("humedad baja desacelera onset")
    elif clase == "fungicas" and h > 75:
        factor = 0.8
        notes.append("alta humedad acelera fungicas")
    elif clase == "bacterianas" and p > 3:
        factor = 0.8
        notes.append("lluvia favorece dispersion bacteriana")
    elif clase == "virales" and t > 28:
        factor = 0.85
        notes.append("temperatura alta favorece vectores")
    elif clase == "plagas_insectos" and 24 <= t <= 32:
        factor = 0.75
        notes.append("temperatura optima acelera ciclo")

    adjMin = max(1, int(round(minD * factor)))
    adjMax = max(adjMin + 1, int(round(maxD * factor)))
    expl = base
    if notes:
        expl += " | ajuste clima: " + ", ".join(notes) + f" -> {adjMin}-{adjMax} dias"
    return {"min_days": adjMin, "max_days": adjMax, "explanation": expl}


def fetch_climate(lat, lon):
    try:
        r = requests.get(
            "https://api.open-meteo.com/v1/forecast",
            params={
                "latitude": lat, "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,precipitation,dew_point_2m",
                "timezone": "auto",
            },
            timeout=5,
        )
        r.raise_for_status()
        cur = r.json().get("current", {})
        return {
            "temp_c": float(cur.get("temperature_2m", 0)),
            "humidity": float(cur.get("relative_humidity_2m", 0)),
            "precip_mm": float(cur.get("precipitation", 0)),
            "dewpoint_c": float(cur.get("dew_point_2m", 0)),
        }
    except Exception:
        return None


def _prob_diseased(scores, labels):
    for i, lab in enumerate(labels):
        l = lab.lower()
        if "enferm" in l or "diseased" in l:
            return float(scores[i])
    return float(scores[-1]) if len(scores) > 1 else float(scores[0])


def _top_class(scores, labels):
    idx = int(np.argmax(scores))
    dist = {labels[i]: round(float(scores[i]), 3) for i in range(len(labels))}
    return labels[idx], float(scores[idx]), dist


@app.post("/api/analyze/zones")
async def analyze_zones(
    image: UploadFile = File(...),
    lat: Optional[float] = Form(None),
    lon: Optional[float] = Form(None),
    patch_size: int = Form(150),
    stride: int = Form(75),
    threshold: float = Form(0.5),
):
    if health_interp is None or disease_interp is None:
        return {"error": "Models not loaded"}

    file_bytes = await image.read()
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name

    try:
        img_bgr = cv2.imread(tmp_path)
        if img_bgr is None:
            return {"error": "Unable to read image"}

        max_side = 600
        h, w = img_bgr.shape[:2]
        if max(h, w) > max_side:
            scale = max_side / max(h, w)
            img_bgr = cv2.resize(img_bgr, (int(w * scale), int(h * scale)))
            h, w = img_bgr.shape[:2]

        zones = []
        total_patches = 0
        class_count = {}
        sevs = []
        levels = []
        order = ["minima", "leve", "moderada", "severa", "critica"]

        for y in range(0, h - patch_size + 1, stride):
            for x in range(0, w - patch_size + 1, stride):
                total_patches += 1
                patch = img_bgr[y:y + patch_size, x:x + patch_size]
                patch_rgb = cv2.cvtColor(patch, cv2.COLOR_BGR2RGB)
                h_scores = run_tflite_from_array(health_interp, patch_rgb)
                p_dis = _prob_diseased(h_scores, health_labels)
                if p_dis < threshold:
                    continue
                d_scores = run_tflite_from_array(disease_interp, patch_rgb)
                cls, conf, dist = _top_class(d_scores, disease_labels)
                sev_pct, sev_lvl, sev_urg = severity_hsv(patch)

                zones.append({
                    "bbox": [int(x), int(y), int(x + patch_size), int(y + patch_size)],
                    "patogeno": cls,
                    "confianza": round(conf, 3),
                    "distribucion": dist,
                    "severidad_pct": sev_pct,
                    "nivel": sev_lvl,
                    "urgencia": sev_urg,
                })
                class_count[cls] = class_count.get(cls, 0) + 1
                sevs.append(sev_pct)
                levels.append(sev_lvl)

        if zones:
            dominant = max(class_count.items(), key=lambda kv: kv[1])[0]
            worst_lvl = max(levels, key=lambda l: order.index(l))
            avg_sev = round(float(np.mean(sevs)), 1)
            max_sev = round(float(np.max(sevs)), 1)
            diseased_pct = round((len(zones) / total_patches) * 100, 1) if total_patches > 0 else 0.0
            overall = {
                "estado": "ENFERMA",
                "zonas_enfermas": len(zones),
                "total_patches": total_patches,
                "porcentaje_enfermo": diseased_pct,
                "porcentaje_sano": round(100 - diseased_pct, 1),
                "clase_dominante": dominant,
                "distribucion_clases": class_count,
                "severidad_promedio": avg_sev,
                "severidad_maxima": max_sev,
                "nivel_global": worst_lvl,
            }
        else:
            overall = {
                "estado": "SANA",
                "zonas_enfermas": 0,
                "total_patches": total_patches,
                "porcentaje_enfermo": 0.0,
                "porcentaje_sano": 100.0,
                "clase_dominante": None,
                "distribucion_clases": {},
                "severidad_promedio": 0.0,
                "severidad_maxima": 0.0,
                "nivel_global": None,
            }

        clima = fetch_climate(lat, lon) if lat is not None and lon is not None else None
        onset = None
        if overall["estado"] == "ENFERMA" and overall["clase_dominante"] and overall["nivel_global"]:
            onset = estimar_onset(overall["clase_dominante"], overall["nivel_global"], clima)

        return {
            "zonas": zones,
            "overall": overall,
            "climate": clima,
            "onset": onset,
        }
    finally:
        Path(tmp_path).unlink(missing_ok=True)


if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
