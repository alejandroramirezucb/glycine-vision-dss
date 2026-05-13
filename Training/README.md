# Training Pipeline

## Requisitos

```bash
pip install tensorflow==2.20.0 albumentations opencv-python-headless scikit-learn huggingface_hub datasets Pillow numpy
```

**Versiones mínimas:**
- TensorFlow 2.20.0+
- Python 3.10+
- albumentations 1.3.0+

## Notebooks

### 01_prepare_dataset.ipynb

Descarga dataset HF + validación.

- Descarga repo desde HuggingFace (sin drive mount, cache local)
- Valida imágenes (PIL.verify, >100px, RGB)
- Dedup por MD5
- Split train/val 80/20 sobre `Train/` (test ya separado en `Test/`)
- Reporte de balance de clases

**Salida:** dataset cacheado en memoria, reporte en stdout.

### 02_train_model1_binary.ipynb

Modelo 1: clasificación binaria (sana/enferma).

**Arquitectura:** EfficientNetB0 (ImageNet) → cabeza propia
- GlobalAveragePooling2D → BatchNorm → Dropout(0.3) → Dense(1, sigmoid)

**Entrenamiento 2-fase:**
1. Base congelada: LR=1e-3, 15 épocas
2. Descongelar últimas 30 capas: LR=1e-5, 25 épocas

**Callbacks:** EarlyStopping, ReduceLROnPlateau, ModelCheckpoint.

**Augmentación:** Albumentations (rotate ±20°, flip H/V, brightness ±10%, hue ±10%, GaussBlur).

**Salida:** `model1_binary.keras`

**Métrica objetivo:** Accuracy >85% en `Test/clasificacion_binaria`.

### 03_train_model2_pathogen.ipynb

Modelo 2: clasificación 5-clase (patógeno).

**Arquitectura:** EfficientNetB0 → cabeza propia
- GlobalAveragePooling2D → BatchNorm → Dropout(0.3) → Dense(5, softmax)

**Entrenamiento 2-fase:** igual que M1 (LR, épocas).

**Class weights:** balanceados (sklearn.utils.class_weight.compute_class_weight).

**Augmentación:** igual que M1.

**Salida:** `model2_pathogen.keras`

**Métrica objetivo:** Macro-F1 >75% en `Test/clasificacion_patogeno`.

### 04_evaluate.ipynb

Métricas detalladas sobre `Test/` oficial.

- Accuracy total + per-class
- Matrices de confusión (seaborn)
- Precision / Recall / F1 por clase
- Gráficos de performance

**Criterio:** Si ambos modelos cumplen métricas, continuar a 05.

### 05_export_tflite.ipynb

Exportar .keras → .tflite + cuantización.

**Pasos:**
1. Cargar `model1_binary.keras` + `model2_pathogen.keras`
2. Convertir a TFLite con `Optimize.DEFAULT` (int8 dinámica)
3. Verificar tamaño <10MB cada uno
4. Salida: `model1.tflite`, `model2.tflite`, `labels.txt` (para cada modelo)

**Verificación:** Prueba inferencia en muestras del dataset.

### 06_inference_demo.ipynb

Demo end-to-end: carga .tflite + imagen real → predicción.

- Carga `model1.tflite` + `model2.tflite`
- Resize imagen a 224×224
- Predice M1 (health)
- Si `diseased`: predice M2 (patógeno)
- Muestra predicción + confianza

## Pipeline completo

```bash
# Colab: cargar solo la carpeta Training/ al repositorio de Colab
# O clonar: https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset

# NB01: Preparar dataset (automático)
# NB02-03: Entrenar (esperando ~30-45 min cada uno en GPU Colab)
# NB04: Evaluar métricas
# NB05: Exportar .tflite
# NB06: Demo

# Descargar outputs/ del Colab a local
# Copiar modelos a App/assets/models/:
cp outputs/model1.tflite ../App/assets/models/hs/model.tflite
cp outputs/model2.tflite ../App/assets/models/pd/model_unquant.tflite
cp outputs/labels_m1.txt ../App/assets/models/hs/labels.txt
cp outputs/labels_m2.txt ../App/assets/models/pd/labels.txt
```

## Módulos Python (src/)

**severity.py** — Segmentación HSV para % enfermedad.

```python
severity_pct, level = calc_severity(image_patch)
# level: "mínima" | "leve" | "moderada" | "severa" | "crítica"
```

**climate.py** — Cliente Open-Meteo.

```python
climate = fetch_climate(lat=-17.78, lon=-63.18)
# {"temp_c": 22.5, "humidity": 75, "precip_mm": 5.2, "dewpoint_c": 18}
```

**onset.py** — Tabla estimación tiempo (clase × severidad × clima).

```python
min_days, max_days = estimar_onset(clase="roya", severidad="moderada", clima={...})
# (5, 10) días
```

**treatments_matrix.py** — Matriz tratamientos (clase × severidad).

```python
tratamiento = get_treatment("fungicas", "severa")
# {"quimico": "...", "cultural": "...", "biologico": "...", "preventivo": "...", "urgencia": "alta"}
```

## Troubleshooting

**Error: "Could not find a version that satisfies the requirement tensorflow==X"**

→ Usar `tensorflow==2.20.0` (última estable) o `tensorflow==2.21.0rc1` (release candidate).

**Error: MLIR conversion failure con float16**

→ Asegurar que entrenamiento está en float32 (no mixed_float16).

**Error: Dataset download timeout**

→ Reintentar. Red de HuggingFace a veces lenta. Colab con GPU típicamente más rápido.

**Error: OOM (Out of Memory)**

→ Reducir batch_size en notebooks (ej: 16 → 8). Colab free = ~10GB RAM.

## Validación

**Checklist antes de copiar a App/assets/models/:**

- [ ] NB04: Accuracy M1 >85%
- [ ] NB04: Macro-F1 M2 >75%
- [ ] NB05: Ambos .tflite <10MB
- [ ] NB06: Inferencia .tflite válida (sin errores)
- [ ] Labels order coinicide en `labels.txt` con `LabelNames.dart`

## Referencias

- [EfficientNet paper](https://arxiv.org/abs/1905.11946)
- [TFLite Optimization](https://www.tensorflow.org/lite/guide/optimize_models)
- [HuggingFace Datasets](https://huggingface.co/docs/datasets)
- [Soybean Dataset](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset)
