<div align="center">
  <img src="assets/logo.png" alt="Glycine Vision DSS" width="180" />
  <br /><br />

# Glycine Vision DSS

Diagnóstico de enfermedades foliares de soya en el dispositivo: detecta, estima severidad y genera recomendaciones de tratamiento ajustadas al clima.

</div>

---

## Pipeline

<div align="center">
  <img src="assets/pipeline.jpg" alt="Diagrama de actividad del pipeline" width="760" />
</div>

- **M_seg**: U-Net ResNet50 256×256, 2 clases (hoja/fondo).
- **M1**: EfficientNetB1 240×240, doble entrada (original + hoja aislada), sigmoid.
- **M2**: EfficientNetB0 224×224, doble entrada, softmax 5 clases (`bacterianas`, `fungicas`, `plagas_insectos`, `roya`, `virales`).
- **Backend**: FastAPI + Docker (mismos modelos por HTTP, opcional).

---

## Estructura

```
glycine-vision-dss/
├── app/                Flutter (Clean Architecture: domain · application · infrastructure · presentation)
│   └── assets/models/{hs,pd,seg}/   M1 · M2 · M_seg (.tflite)
├── backend/            FastAPI (server.py, config.py, inference/, services/, Dockerfile)
├── training/notebooks/ 01–13 (Google Colab / Kaggle) + requirements.txt
├── models/             Modelos desplegados {health,disease,segmentation}/ (no versionado)
├── paper/              Manuscrito (articulo-cientifico.docx · .pdf)
├── TRAZABILIDAD.md     Mapa afirmación del artículo → código y evidencia
├── DATASET_CARD.md     Tarjeta del dataset (fuentes, licencias, curación)
├── MODEL_CARD.md       Tarjeta de los modelos publicados en Hugging Face
├── assets/             Logo del proyecto
├── CITATION.cff        Metadatos de cita (formato CFF)
└── docker-compose.yml
```

---

## Licencias

El proyecto combina tres componentes con condiciones distintas. No es posible unificarlos bajo una sola licencia
porque los datos derivan de fuentes de terceros con restricciones propias.

| Componente | Licencia | Alcance |
|---|---|---|
| Código (app, backend, notebooks) | **MIT** (`LICENSE`) | Uso libre con atribución |
| Manuscrito (`paper/`) | **CC BY 4.0** | Declarado en el artículo |
| Dataset curado | **Indeterminada, no comercial** | Deriva de fuentes mixtas; véase [DATASET_CARD.md](DATASET_CARD.md) |
| Modelos entrenados (`models/`, `app/assets/models/`) | Siguen la condición del dataset | Uso académico |

El dataset hereda **CC BY-NC-SA 4.0** de PlantVillage y contiene dos fuentes sin licencia declarada, por lo que el
conjunto combinado **no debe asumirse reutilizable comercialmente**.

---

## Ejecutar la app

```bash
cd app
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
cd backend
python -m venv env
.\env\Scripts\Activate.ps1
pip install -r requirements.txt
python server.py
```

| Variable de entorno | Default | Descripción |
|---|---|---|
| `MODELS_DIR` | `../models` | Ruta a la carpeta de modelos |

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
| `01_preparacion_datos.ipynb` | Descarga datasets (HF) + dedup (MD5 + pHash, sin fuga train/test) + split train/val + Test; máscaras COCO (Roboflow + SoyCotton) | `splits/` |
| `02_entrenamiento_segmentacion.ipynb` | M_seg ResNet50 U-Net hoja/fondo (COCO fusionado) | `model_seg.keras` (+ `.tflite`) |
| `03_entrenamiento_m1_estado_sanitario.ipynb` | M1 EfficientNetB1 doble entrada (hoja aislada por M_seg + Shades-of-Gray) | `model1_binary.keras` |
| `04_entrenamiento_m2_patogeno.ipynb` | M2 EfficientNetB0 doble entrada softmax | `model2_pathogen.keras` |
| `05_evaluacion_modelos.ipynb` | Métricas en test (M1/M2 + IC95% bootstrap; M_seg recall/Dice/IoU vs COCO) | `training_metrics.json`, `mseg_test_metrics.json` |
| `06_exportacion_tflite.ipynb` | Export TFLite float32 + int8, equivalencia Keras↔TFLite, labels | `.tflite`, `model_metadata.json` |
| `07_validacion_frente_a_experto.ipynb` | Severidad CIELab (M_seg + reglas de color) y patógeno de la app vs. experto (n=60): Pearson, CCC, MAE, RMSE, Bland-Altman, McNemar | `comparacion_app_vs_experto.json` |
| `08_diagnostico_baselines.ipynb` | Diagnóstico rápido de baselines vs. propuesto (M2, 1 semilla, presupuesto reducido) | `diagnostico_m2.csv` |
| `09_ablacion_presupuesto_reducido.ipynb` | Baselines y ablación por componente (M2, 3 semillas): media ± desviación | `baselines_m2.csv`, `ablation_m2.csv` |
| `10_verificacion_presupuesto_completo.ipynb` | Verificación al presupuesto completo (propuesto vs. EfficientNetB0 de una entrada) | `verificacion_full_m2.csv` |
| `11_ablacion_presupuesto_completo.ipynb` | Ablación por componente al presupuesto completo (20+45, datos completos, 3 semillas) | `ablation_full_m2.csv` |
| `12_calibracion_probabilidades.ipynb` | Calibración de M1 y M2: ECE, MCE, Brier y diagramas de confiabilidad | `calibracion.csv`, `calibracion.json` |
| `13_evaluacion_variantes_exportadas.ipynb` | Keras vs. TFLite float32 vs. int8 en el test: exactitud, F1 y diferencias | `evaluacion_variantes.csv`, `.json` |

**Máscaras de segmentación (M_seg):**
- Tus máscaras de Roboflow → `training/splits/masks/` (con `_annotations.coco.json`).
- Dataset SoyCotton (figshare CC BY 4.0) → `training/splits/masks_soycotton/annotations/` (JSON COCO) + `training/splits/masks_soycotton/images/` (imágenes). El notebook 02 las **fusiona** automáticamente. La celda de descarga del notebook 01 reproduce esa estructura.

Tras mejorar solo M_seg: reentrenar `02`, reejecutar `05` (métricas) y `06` (export). M1/M2 (`03`/`04`) no requieren reentrenamiento.

---

## Desplegar modelos entrenados

Desde la raíz del proyecto, tras completar los notebooks:

```powershell
$SRC = "training/outputs"; $APP = "app/assets/models"; $MOD = "models"

Copy-Item "$SRC/model1_int8.tflite"    "$APP/hs/model.tflite" -Force
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
