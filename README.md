<div align="center">
  <img src="Images/logo.png" alt="Glycine Vision DSS" width="180" />
  <br /><br />

# Glycine Vision DSS

Diagnóstico de enfermedades foliares de soya en el dispositivo: detecta, estima severidad y genera recomendaciones de tratamiento ajustadas al clima.

</div>

---

## Pipeline

```
imagen → M_seg (hoja/fondo) → hoja aislada → M1 [original+hoja] sana/enferma
                                                  │ (si enferma)
                                                  ▼
                                   M2 [original+hoja] tipo de patógeno + severidad por color
```

- **M_seg**: U-Net ResNet50 256×256, 2 clases (hoja/fondo).
- **M1**: EfficientNetB1 240×240, doble entrada (original + hoja aislada), sigmoid.
- **M2**: EfficientNetB0 224×224, doble entrada, softmax 5 clases (`bacterianas`, `fungicas`, `plagas_insectos`, `roya`, `virales`).
- **Backend**: FastAPI + Docker (mismos modelos por HTTP, opcional).

---

## Estructura

```
glycine-vision-dss/
├── App/                Flutter app (Clean Architecture)
│   └── assets/models/{hs,pd,seg}/   M1 · M2 · M_seg (.tflite)
├── Backend/            FastAPI (server.py, config.py, inference/, Dockerfile)
├── Models/             Modelos desplegados {health,disease,segmentation}/
├── Training/notebooks/ 01–06 (Google Colab)
└── docker-compose.yml
```

---

## Ejecutar la app

```bash
cd App
flutter pub get
flutter run -d <device_id>      # Android / iOS
flutter run -d chrome           # Web (requiere el backend corriendo)
```

Requisitos: Flutter 3.x, Android SDK ≥31, Dart ≥3.0.

## Ejecutar el backend

**Docker (recomendado):**
```bash
docker compose up --build       # API en http://localhost:8001
```

**Manual:**
```bash
cd Backend
python -m venv env
.\env\Scripts\Activate.ps1
pip install -r requirements.txt
python server.py
```

| Variable de entorno | Default | Descripción |
|---|---|---|
| `MODELS_DIR` | `../Models` | Ruta a la carpeta de modelos |

### API

```bash
curl -X POST http://localhost:8001/api/diagnose \
  -F "image=@leaf.jpg" -F "lat=-17.5" -F "lon=-65.3"
```

Respuesta: `enfermedades_detectadas`, `global_severity_pct`, `seg_mask` (base64 uint8 256×256), `climate`.

---

## Entrenar (Google Colab, GPU)

Ejecutar los notebooks en orden. M_seg se entrena **antes** que M1/M2 (produce la hoja aislada que es su segunda entrada).

| Notebook | Hace | Salida |
|---|---|---|
| `01_prepare_dataset.ipynb` | Descarga datasets (HF) + split train/val + Test; prepara máscaras COCO (Roboflow + SoyCotton) | `splits/` |
| `02_train_segmentation.ipynb` | M_seg ResNet50 U-Net hoja/fondo (COCO fusionado) | `model_seg.tflite` |
| `03_train_model1_binary.ipynb` | M1 EfficientNetB1 doble entrada | `model1.tflite` |
| `04_train_model2_pathogen.ipynb` | M2 EfficientNetB0 doble entrada softmax | `model2.tflite` |
| `05_evaluate.ipynb` | Métricas en test (M1/M2; M_seg recall/Dice/IoU vs COCO) | `training_metrics.json`, `mseg_test_metrics.json` |
| `06_export_tflite.ipynb` | Export TFLite float32 + int8 | `.tflite` |

**Máscaras de segmentación (M_seg):**
- Tus máscaras de Roboflow → `Training/splits/masks/` (con `_annotations.coco.json`).
- Dataset SoyCotton (figshare CC BY 4.0) → `Training/splits/masks_soycotton/annotations/` (JSON COCO) + `Training/splits/masks_soycotton/images/` (imágenes). El notebook 02 las **fusiona** automáticamente. La celda de descarga del notebook 01 reproduce esa estructura.

Tras mejorar solo M_seg: reentrenar `02`, reejecutar `05` (métricas) y `06` (export). M1/M2 (`03`/`04`) no requieren reentrenamiento.

---

## Desplegar modelos entrenados

Desde la raíz del proyecto, tras completar los notebooks:

```powershell
$SRC = "Training/outputs"; $APP = "App/assets/models"; $MOD = "Models"

Copy-Item "$SRC/model1.tflite"         "$APP/hs/model.tflite" -Force
Copy-Item "$SRC/labels_m1.txt"         "$APP/hs/labels.txt" -Force
Copy-Item "$SRC/model2.tflite"         "$APP/pd/model_unquant.tflite" -Force
Copy-Item "$SRC/labels_m2.txt"         "$APP/pd/labels.txt" -Force
Copy-Item "$SRC/model_seg_int8.tflite" "$APP/seg/model_seg.tflite" -Force

Copy-Item "$SRC/model1.tflite"         "$MOD/health/model.tflite" -Force
Copy-Item "$SRC/model1_int8.tflite"    "$MOD/health/model_int8.tflite" -Force
Copy-Item "$SRC/labels_m1.txt"         "$MOD/health/labels.txt" -Force
Copy-Item "$SRC/model2.tflite"         "$MOD/disease/model.tflite" -Force
Copy-Item "$SRC/model2_int8.tflite"    "$MOD/disease/model_int8.tflite" -Force
Copy-Item "$SRC/labels_m2.txt"         "$MOD/disease/labels.txt" -Force
Copy-Item "$SRC/model_seg.tflite"      "$MOD/segmentation/model.tflite" -Force
Copy-Item "$SRC/model_seg_int8.tflite" "$MOD/segmentation/model_int8.tflite" -Force
Write-Host "Deploy OK"
```
