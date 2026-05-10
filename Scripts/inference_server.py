from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
import tensorflow as tf
from tensorflow.keras.models import load_model
import warnings
warnings.filterwarnings('ignore')

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

try:
    health_model = load_model("Models/glycine-vision-hs/keras_model.h5", compile=False, safe_mode=False)
    print("✓ Health model loaded")
except Exception as e:
    print(f"Health model load failed, trying fallback: {str(e)[:100]}")
    health_model = None

try:
    disease_model = load_model("Models/glycine-vision-pd/keras_model.h5", compile=False, safe_mode=False)
    print("✓ Disease model loaded")
except Exception as e:
    print(f"Disease model load failed, trying fallback: {str(e)[:100]}")
    disease_model = None

def load_labels(path):
    with open(path) as f:
        return [l.strip() for l in f.readlines() if l.strip()]

health_labels = load_labels("Models/glycine-vision-hs/labels.txt")
disease_labels = load_labels("Models/glycine-vision-pd/labels.txt")

def preprocess(image_path):
    img = Image.open(image_path).convert('RGB').resize((224, 224))
    arr = np.array(img, dtype=np.float32) / 127.5 - 1.0
    return np.expand_dims(arr, 0)

@app.post("/api/classify/health")
async def classify_health(file: UploadFile = File(...)):
    if not health_model:
        return {"error": "Model not loaded"}
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    try:
        pred = health_model.predict(preprocess(tmp_path), verbose=0)
        results = [{"label": health_labels[i], "confidence": float(pred[0][i])} for i in range(len(health_labels))]
        results.sort(key=lambda x: x["confidence"], reverse=True)
        return {"predictions": results}
    finally:
        Path(tmp_path).unlink()

@app.post("/api/classify/disease")
async def classify_disease(file: UploadFile = File(...)):
    if not disease_model:
        return {"error": "Model not loaded"}
    with tempfile.NamedTemporaryFile(delete=False) as tmp:
        tmp.write(await file.read())
        tmp_path = tmp.name
    try:
        pred = disease_model.predict(preprocess(tmp_path), verbose=0)
        results = [{"label": disease_labels[i], "confidence": float(pred[0][i])} for i in range(len(disease_labels))]
        results.sort(key=lambda x: x["confidence"], reverse=True)
        return {"predictions": results}
    finally:
        Path(tmp_path).unlink()

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
