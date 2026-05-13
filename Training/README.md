# Training — Glycine Vision v2

Pipeline reproducible de entrenamiento de los modelos M1 (binario sana/enferma) y M2 (5 clases de patógeno) basado en transfer learning con EfficientNetB0, ejecutable en Google Colab gratuito.

## Dataset

Dataset publicado en HuggingFace: [`alejandroramirezucb/soybean_image_dataset`](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset)

Estructura esperada tras descarga:

```
data/
├── Train/
│   ├── clasificacion_binaria/
│   │   ├── soya_sana/
│   │   └── soya_enferma/
│   └── clasificacion_patogeno/
│       ├── bacterianas/
│       ├── fungicas/
│       ├── plagas_insectos/
│       ├── roya/
│       └── virales/
└── Test/   (misma estructura)
```

El notebook `01_prepare_dataset.ipynb` descarga el dataset automáticamente vía `huggingface_hub`. No requiere mount de Drive.

## Estructura

```
Training/
├── README.md
├── requirements.txt
├── notebooks/
│   ├── 01_prepare_dataset.ipynb       # Descarga HF + validación + split train/val
│   ├── 02_train_model1_binary.ipynb   # M1: sana vs enferma
│   ├── 03_train_model2_pathogen.ipynb # M2: 5 clases patógeno
│   ├── 04_evaluate.ipynb              # Métricas + matrices de confusión
│   ├── 05_export_tflite.ipynb         # Cuantización + export .tflite
│   └── 06_inference_demo.ipynb        # Pipeline completo con imagen real
├── src/
│   ├── severity.py                    # HSV severity calculator
│   ├── climate.py                     # Open-Meteo client
│   ├── onset.py                       # Tiempo de onset (clase × severidad × clima)
│   ├── treatments_matrix.py           # Matriz tratamientos (clase × severidad)
│   └── inference.py                   # Pipeline sliding window completo
└── outputs/                           # Modelos entrenados (.keras + .tflite)
```

## Ejecución en Colab

1. Abrir Colab → `Runtime → Change runtime type → GPU (T4)`.
2. Clonar el repo o subir la carpeta `Training/`.
3. Ejecutar `01_prepare_dataset.ipynb` (descarga ~500MB del dataset HF).
4. Ejecutar `02_train_model1_binary.ipynb` (~50 min en T4).
5. Ejecutar `03_train_model2_pathogen.ipynb` (~80 min en T4).
6. Ejecutar `04_evaluate.ipynb` para validar métricas.
7. Ejecutar `05_export_tflite.ipynb` para generar `.tflite` cuantizados.
8. Descargar `outputs/model1.tflite` y `outputs/model2.tflite`.
9. Copiar a `Code/assets/models/hs/model.tflite` y `Code/assets/models/pd/model_unquant.tflite`.

## Salidas esperadas

- `outputs/model1_binary.keras` — modelo M1 sin cuantizar
- `outputs/model2_pathogen.keras` — modelo M2 sin cuantizar
- `outputs/model1.tflite` — M1 cuantizado int8 (<5MB)
- `outputs/model2.tflite` — M2 cuantizado int8 (<10MB)
- `outputs/labels_m1.txt` — labels M1 (`soya_sana`, `soya_enferma`)
- `outputs/labels_m2.txt` — labels M2 (`bacterianas`, `fungicas`, `plagas_insectos`, `roya`, `virales`)
- `outputs/class_indices_m2.json` — mapping índice → clase
- `outputs/training_metrics.json` — accuracy, F1 por clase, matrices de confusión

## Métricas objetivo

| Modelo     | Métrica       | Objetivo |
| ---------- | ------------- | -------- |
| M1 binary  | Accuracy test | ≥ 0.85   |
| M1 binary  | F1 score      | ≥ 0.85   |
| M2 5-class | Accuracy test | ≥ 0.75   |
| M2 5-class | Macro F1      | ≥ 0.70   |
| M2 5-class | F1 por clase  | ≥ 0.65   |
