<div align="center">
  <img src="Images/logo.png" alt="Glycine Vision DSS" width="180" />
  <br /><br />

# Glycine Vision DSS

Decision Support System for soybean leaf disease diagnosis using on-device machine learning.

Detects and classifies diseases from a smartphone photo, estimates severity, and generates agronomic treatment recommendations adjusted for current climate.

</div>

---

## Architecture

```
┌─────────────────────────────────┐
│  Flutter App (iOS / Android)    │
│  ┌──────────────────────────┐   │
│  │ M1 — binary health check │   │  EfficientNetB1 240×240
│  │ healthy vs diseased       │   │  float32, on-device
│  ├──────────────────────────┤   │
│  │ M2 — single-label 5 class│   │  EfficientNetB0 224×224
│  │ bacterianas/fungicas/...  │   │  softmax, cross-entropy
│  ├──────────────────────────┤   │
│  │ M_seg — U-Net semantic   │   │  ResNet50 encoder 256×256
│  │ bg / sana / enferma       │   │  int8, pseudo-labels HSV
│  └──────────────────────────┘   │
└─────────────────────────────────┘
         │  optional remote fallback
         ▼
┌─────────────────────────────────┐
│  Backend  FastAPI + Docker      │
│  same models via HTTP API       │
└─────────────────────────────────┘
```

**Disease classes (M2):** `bacterianas` · `fungicas` · `plagas_insectos` · `roya` · `virales`

**Severity levels:** `minima` (<5%) · `leve` (5-15%) · `moderada` (15-35%) · `severa` (35-60%) · `critica` (≥60%)

---

## Project structure

```
glycine-vision-dss/
├── App/                     Flutter mobile app (MVVM + Clean Architecture)
│   ├── lib/
│   │   ├── domain/          Entity classes (one class per file)
│   │   ├── infrastructure/  TFLite, HTTP, treatment repo, SOLID
│   │   ├── application/     Use cases
│   │   └── presentation/    Screens, widgets, state
│   └── assets/
│       ├── models/hs/       M1 binary health model
│       ├── models/pd/       M2 pathogen model
│       ├── models/seg/      M_seg segmentation model
│       └── data/            tratamientos.json (schema v2)
├── Backend/                 FastAPI inference server
│   ├── server.py            Routes only (SOLID)
│   ├── config.py            Constants + MODELS_DIR env var
│   ├── inference/           ModelRegistry, DiagnosisService, etc.
│   ├── services/            ClimateService (Open-Meteo)
│   ├── Dockerfile
│   └── requirements.txt
├── Models/                  Trained models organized by type
│   ├── health/              model.tflite, model_int8.tflite, labels.txt
│   ├── disease/             model.tflite, model_int8.tflite, labels.txt
│   └── segmentation/        model.tflite, model_int8.tflite
├── Training/
│   └── notebooks/           01-06 Colab training notebooks
└── docker-compose.yml
```

---

## Setup

### Flutter App

```bash
cd App
flutter pub get
flutter run -d <device_id>      # Android / iOS
flutter run -d chrome           # Web (requires Backend running)
```

**Requirements:** Flutter 3.x, Android SDK ≥31, Dart ≥3.0

### Backend (Docker — recommended)

```bash
docker compose up --build
# API available at http://localhost:8001
```

**Manual:**
```bash
cd Backend

python -m venv env
.\env\Scripts\Activate.ps1

pip install -r requirements.txt
python server.py
```

| Environment variable | Default | Description |
|---|---|---|
| `MODELS_DIR` | `../Models` | Path to models directory |

---

## Deploy trained models

Run from project root after completing training notebooks. M2 es single-label (softmax), no usa thresholds.

**PowerShell (Windows):**
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

---

## Training

Notebooks run on **Google Colab** (GPU required). Execute in order:

| Notebook | Description | Key output |
|---|---|---|
| `01_prepare_dataset.ipynb` | Download + split dataset | `splits/` |
| `02_train_model1_binary.ipynb` | M1 EfficientNetB1 binary | `model1.tflite` |
| `03_train_model2_pathogen.ipynb` | M2 EfficientNetB0 single-label softmax | `model2.tflite` |
| `04_train_segmentation.ipynb` | M_seg ResNet50 U-Net | `model_seg_int8.tflite` |
| `05_evaluate.ipynb` | Full metrics on test set | `training_metrics.json` |
| `06_export_tflite.ipynb` | TFLite export + int8 quant | All `.tflite` files |

---

## Model performance

Evaluado sobre el test set independiente (`splits/test/`, balanceado por clase).

| Model | Metric | Value | Target |
|---|---|---|---|
| M1 | Accuracy | 0.98 | ≥0.98 ✅ |
| M1 | F1 | 0.98 | ≥0.98 ✅ |
| M1 | Recall (enferma) | 0.96 | ≥0.97 ⚠️ |
| M2 | Accuracy | 0.949 | ≥0.9514 ⚠️ |
| M2 | F1 macro | 0.948 | ≥0.9472 ✅ |
| M_seg | Dice enferma | 0.949 | ≥0.65 ✅ |
| M_seg | Dice sana | 0.866 | — |

M2 F1 por clase: bacterianas 0.919 · fungicas 0.884 · plagas_insectos 0.993 · roya 0.944 · virales 1.000.

**Estado actual / mejoras:**
- `fungicas` es la clase más débil (F1 0.884): se confunde con bacterianas/roya → más datos fúngicos variados.
- M1 recall 0.96 (<0.97): faltan imágenes de enfermedad temprana (los falsos negativos son el error más costoso).
- M_seg: excelente en textura sana/enferma, pero confunde hoja con suelo en fondos complejos → mitigado con la Fase 3 (máscaras COCO reales).

---

## API reference

### POST /api/diagnose

```bash
curl -X POST http://localhost:8001/api/diagnose \
  -F "image=@leaf.jpg" \
  -F "lat=-17.5" \
  -F "lon=-65.3"
```

Response includes: `enfermedades_detectadas`, `global_severity_pct`, `seg_mask` (base64 uint8 256×256), `climate`.

---

## Treatment database

`App/assets/data/tratamientos.json` — schema v2. Structured agronomic recommendations with:
- Per-disease, per-severity: `chemical`, `cultural`, `biological`, `preventive`
- Numeric doses: `dose_g_per_100L`, `dose_L_per_ha`, `severity_multiplier`
- References: `cas_number`, `eppo_code`, `pre_harvest_days`
- Incompatibility matrix, application windows

Dose formula: `total = base_per_ha × field_area_ha × severity_multiplier[level]`

---

## Known limitations

1. **M_seg pseudo-labels (Fases 1–2)**: entrenadas contra máscaras HSV, no anotaciones de experto. La Fase 3 incorpora máscaras reales (COCO) para el límite hoja/fondo; la separación sana/enferma sigue basada en HSV.
2. **Fondos complejos**: M_seg puede confundir suelo/hojas de fondo con tejido foliar. La Fase 3 lo mitiga; aislar una sola hoja mejora el resultado.
3. **fungicas**: clase con más confusión (F1 0.884) por similitud visual con bacterianas/roya temprana. Requiere más datos fúngicos variados.
4. **Treatment doses**: derived from agronomic literature (CABI, ANAPO). No certified database API for Latin American soybean — consult local agronomist before application.

### Metodología de evaluación
- M1/M2 se evalúan sobre un **test set independiente** (carpeta `Test/` del dataset HF, balanceada: 100/clase M1, 70/clase M2), separado del train/val (split 80/20). Test held-out + balanceado = estándar para clasificación y evita fuga de datos.
- Data augmentation: **on-the-fly** (albumentations) durante el entrenamiento; no se usa dataset sintético offline.
