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
│  │ M2 — multi-label 5 class │   │  EfficientNetB0 224×224
│  │ bacterianas/fungicas/...  │   │  sigmoid, ASL loss
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
│   ├── disease/             model.tflite, labels.txt, thresholds.json
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
pip install -r requirements.txt
python server.py
```

| Environment variable | Default | Description |
|---|---|---|
| `MODELS_DIR` | `../Models` | Path to models directory |

---

## Deploy trained models

Run from project root after completing training notebooks:

```bash
SRC="Training/outputs"
APP="App/assets/models"
MOD="Models"

cp "$SRC/model1.tflite"         "$APP/hs/model.tflite"
cp "$SRC/labels_m1.txt"         "$APP/hs/labels.txt"
cp "$SRC/hs_threshold.json"     "$APP/hs/threshold.json"
cp "$SRC/model2.tflite"         "$APP/pd/model_unquant.tflite"
cp "$SRC/labels_m2.txt"         "$APP/pd/labels.txt"
cp "$SRC/thresholds.json"       "$APP/pd/thresholds.json"
cp "$SRC/model_seg_int8.tflite" "$APP/seg/model_seg.tflite"

mkdir -p "$MOD/health" "$MOD/disease" "$MOD/segmentation"
cp "$SRC/model1.tflite"         "$MOD/health/model.tflite"
cp "$SRC/model1_int8.tflite"    "$MOD/health/model_int8.tflite"
cp "$SRC/labels_m1.txt"         "$MOD/health/labels.txt"
cp "$SRC/hs_threshold.json"     "$MOD/health/threshold.json"
cp "$SRC/model2.tflite"         "$MOD/disease/model.tflite"
cp "$SRC/model2_int8.tflite"    "$MOD/disease/model_int8.tflite"
cp "$SRC/labels_m2.txt"         "$MOD/disease/labels.txt"
cp "$SRC/thresholds.json"       "$MOD/disease/thresholds.json"
cp "$SRC/model_seg.tflite"      "$MOD/segmentation/model.tflite"
cp "$SRC/model_seg_int8.tflite" "$MOD/segmentation/model_int8.tflite"

echo "Deploy OK"
```

---

## Training

Notebooks run on **Google Colab** (GPU required). Execute in order:

| Notebook | Description | Key output |
|---|---|---|
| `01_prepare_dataset.ipynb` | Download + split dataset | `splits/` |
| `02_train_model1_binary.ipynb` | M1 EfficientNetB1 binary | `model1.tflite` |
| `03_train_model2_pathogen.ipynb` | M2 EfficientNetB0 multi-label | `model2.tflite` + `thresholds.json` |
| `04_train_segmentation.ipynb` | M_seg ResNet50 U-Net | `model_seg_int8.tflite` |
| `05_evaluate.ipynb` | Full metrics on test set | `training_metrics.json` |
| `06_export_tflite.ipynb` | TFLite export + int8 quant | All `.tflite` files |

---

## Model performance

| Model | Metric | Value | Target |
|---|---|---|---|
| M1 | Accuracy | 0.98 | ≥0.85 ✅ |
| M1 | F1 | 0.98 | ≥0.85 ✅ |
| M2 | mAP | 0.80 | ≥0.85 ⚠️ |
| M2 | F1 macro | 0.45 | ≥0.80 ❌ |
| M_seg | Dice enferma | 0.95 | ≥0.65 ✅ |
| M_seg | CCC severidad | 0.95 | ≥0.85 ✅ |
| M_seg | MAE severidad | 1.97% | ≤15% ✅ |

**M2 known issues:**
- `virales` AP=0 → insufficient training samples, model cannot separate virales visually
- `roya` F1≈0 at threshold=0.40 → threshold too high for absolute score range; recalibrate with `[0.05, 0.60]`

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

1. **M_seg pseudo-labels**: trained against HSV-generated masks, not expert annotations. Dice/CCC metrics measure similarity to HSV reference. Scientific validation requires expert-annotated ground truth.
2. **Multi-leaf images**: M_seg may misclassify background leaves as leaf tissue. Use the crop feature (camera mode) to isolate a single leaf before diagnosis.
3. **virales detection**: very low F1 due to limited training data. More diverse viral symptom images required.
4. **Treatment doses**: derived from agronomic literature (CABI, ANAPO, Ridnik et al.). No certified database API available for Latin American soybean — consult local agronomist before application.
