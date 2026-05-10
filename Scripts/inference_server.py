from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
import tempfile
from pathlib import Path
import numpy as np
from PIL import Image
import tensorflow as tf
import warnings
warnings.filterwarnings('ignore')

app = FastAPI()
app.add_middleware(CORSMiddleware, allow_origins=["*"], allow_methods=["*"], allow_headers=["*"])

def load_tflite(path):
    interp = tf.lite.Interpreter(model_path=str(path))
    interp.allocate_tensors()
    return interp

def load_labels(path):
    labels = []
    for line in Path(path).read_text().splitlines():
        line = line.strip()
        if not line:
            continue
        parts = line.split(' ', 1)
        labels.append(parts[1] if len(parts) == 2 and parts[0].isdigit() else line)
    return labels

try:
    health_interp = load_tflite("Models/glycine-vision-hs/model.tflite")
    health_labels = load_labels("Models/glycine-vision-hs/labels.txt")
    print("✓ Health model loaded")
except Exception as e:
    health_interp = None
    print(f"Health model load failed: {e}")

try:
    disease_interp = load_tflite("Models/glycine-vision-pd/model_unquant.tflite")
    disease_labels = load_labels("Models/glycine-vision-pd/labels.txt")
    print("✓ Disease model loaded")
except Exception as e:
    disease_interp = None
    print(f"Disease model load failed: {e}")

def preprocess(image_path, dtype):
    img = Image.open(image_path).convert('RGB').resize((224, 224))
    arr = np.array(img)
    if dtype == np.float32:
        arr = arr.astype(np.float32) / 127.5 - 1.0
    else:
        arr = arr.astype(dtype)
    return np.expand_dims(arr, 0)

def run_tflite(interp, image_path):
    inp = interp.get_input_details()[0]
    out = interp.get_output_details()[0]
    interp.set_tensor(inp['index'], preprocess(image_path, inp['dtype']))
    interp.invoke()
    raw = interp.get_tensor(out['index'])[0]
    if out['dtype'] == np.uint8:
        return raw.astype(np.float32) / 255.0
    return raw.astype(np.float32)

def classify(interp, labels, file_bytes):
    if interp is None:
        return {"error": "Model not loaded"}
    with tempfile.NamedTemporaryFile(delete=False, suffix=".jpg") as tmp:
        tmp.write(file_bytes)
        tmp_path = tmp.name
    try:
        scores = run_tflite(interp, tmp_path)
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8001)
