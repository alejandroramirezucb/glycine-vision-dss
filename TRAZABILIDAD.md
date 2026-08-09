# Trazabilidad: afirmaciones del artículo → código y evidencia

Este documento enlaza cada afirmación cuantitativa y metodológica de `paper/articulo-cientifico.docx`
con el código que la produce y con el archivo de resultados que la respalda. Su propósito es que
cualquier revisor pueda verificar, sin ejecutar el proyecto completo, de dónde sale cada número.

Convenciones: los notebooks están en `training/notebooks/`, sus salidas en `training/outputs/`,
y el código de inferencia en `backend/inference/`.

Recursos publicados: el dataset curado en
[Hugging Face](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset), los modelos entrenados en
[Hugging Face](https://huggingface.co/alejandroramirezucb/glycine-vision-models) y los archivos de resultados en el
[release v1.0-paper](https://github.com/alejandroramirezucb/glycine-vision-dss/releases/tag/v1.0-paper).

---

## 1. Resultados cuantitativos

| Afirmación en el artículo | Valor | Notebook que lo genera | Archivo de evidencia |
|---|---|---|---|
| M_seg: recall de hoja | 0.977 | `05_evaluacion_modelos.ipynb` | `mseg_test_metrics.json` → `leaf_recall` |
| M_seg: Dice | 0.885 | `05_evaluacion_modelos.ipynb` | `mseg_test_metrics.json` → `dice` |
| M_seg: IoU | 0.808 | `05_evaluacion_modelos.ipynb` | `mseg_test_metrics.json` → `iou` |
| M1: exactitud (IC 95 %) | 0.980 (0.960–0.995) | `05_evaluacion_modelos.ipynb` | `training_metrics.json` → `m1.accuracy`, `m1.ci95.accuracy` |
| M1: recall clase enferma | 1.000 | `05_evaluacion_modelos.ipynb` | `training_metrics.json` → `m1.recall_enferma` |
| M2: exactitud (IC 95 %) | 0.969 (0.949–0.986) | `05_evaluacion_modelos.ipynb` | `training_metrics.json` → `m2.accuracy`, `m2.ci95.accuracy` |
| M2: F1 macro | 0.968 | `05_evaluacion_modelos.ipynb` | `training_metrics.json` → `m2.f1_macro` |
| M2: F1 por clase | 0.950 / 0.920 / 0.986 / 0.986 / 1.000 | `05_evaluacion_modelos.ipynb` | `training_metrics.json` → `m2.per_class_f1` |
| Severidad vs. experto: r, CCC, MAE, RMSE | 0.967, 0.941, 5.7 %, 7.4 % | `07_validacion_frente_a_experto.ipynb` | `comparacion_app_vs_experto.json` → `severidad` |
| Bland-Altman: sesgo y límites de acuerdo | −5.0 %, [−15.8, 5.9] | `07_validacion_frente_a_experto.ipynb` | `comparacion_app_vs_experto.json` → `severidad.bias`, `loa_low`, `loa_high` |
| Patógeno app vs. experto y McNemar | 0.950 vs. 0.867; p = 0.0625 | `07_validacion_frente_a_experto.ipynb` | `comparacion_app_vs_experto.json` → `patogeno` |
| Costo computacional (parámetros, MACs, tamaño) | Tabla 3 del artículo | `06_exportacion_tflite.ipynb` | `model_metadata.json` y tamaños de `.tflite` |
| Ablación por componente (media ± DE, 3 semillas) | Tabla 5 del artículo | `11_ablacion_presupuesto_completo.ipynb` | `ablation_full_m2.csv`, `raw_results_full_m2.csv` |
| Comparación con baseline de una sola entrada | 0.969 vs. 0.963 | `10_verificacion_presupuesto_completo.ipynb` | `verificacion_full_m2.csv` |
| Calibración: ECE, MCE, Brier | M1 0.011 / 0.63 / 0.016; M2 0.039 / 0.55 / 0.049 | `12_calibracion_probabilidades.ipynb` | `calibracion.json`, `calibracion.csv` |
| Variantes exportadas (Keras, float32, int8) | Tabla 4 del artículo | `13_evaluacion_variantes_exportadas.ipynb` | `evaluacion_variantes.csv`, `.json` |
| Latencia y memoria en dispositivo | 126 / 19 / 12 ms; 120 / 54 / 40 MB | Medición externa con `benchmark_model` (TFLite) vía `adb` sobre Xiaomi 2203129G | Salida de consola del benchmark |

---

## 2. Afirmaciones metodológicas

| Afirmación en el artículo | Dónde se implementa |
|---|---|
| Segmentación U-Net con codificador ResNet50, entrada 256 × 256, dos clases | `02_entrenamiento_segmentacion.ipynb` |
| Posprocesamiento por mayor componente conexo | `backend/inference/segmenter.py` → `_largest_component` |
| M1: EfficientNetB1, 240 × 240, salida sigmoide | `03_entrenamiento_m1_estado_sanitario.ipynb` |
| M2: EfficientNetB0, 224 × 224, softmax de cinco clases | `04_entrenamiento_m2_patogeno.ipynb` |
| Doble entrada: imagen original y hoja aislada | `03…`, `04…` (entradas `original` y `hoja_aislada`); `backend/inference/classifier.py` |
| La hoja aislada proviene de M_seg (no de umbrales HSV) | `mseg_mask()` en `03…` y `04…`; `backend/inference/diagnosis.py` |
| Normalización Shades-of-Gray (Minkowski p = 6, ganancia acotada a [0.6, 1.6]) | `chromatic_normalize()` en `02…`–`05…`, `07…`; `backend/inference/preprocessor.py` |
| Misma normalización en entrenamiento e inferencia | `training/notebooks/*` y `backend/inference/preprocessor.py` |
| Pérdida focal binaria con balanceo (M1) | `03_entrenamiento_m1_estado_sanitario.ipynb` |
| Entropía cruzada con suavizado de etiquetas (M2) | `04_entrenamiento_m2_patogeno.ipynb` |
| Promediado exponencial de pesos (EMA) | `EMACallback` en `03…`, `04…`, `09…`, `11…` |
| Deduplicación por MD5 y hash perceptual (pHash), sin fuga train/test | `deduplicar_y_limpiar()` en `01_preparacion_datos.ipynb` |
| Filtros de calidad: apertura válida, RGB, mínimo 224 × 224 px | `validar()` en `01_preparacion_datos.ipynb` |
| Semilla fija (42) y partición 80/20 | `01_preparacion_datos.ipynb` (`train_test_split(..., random_state=42)`) |
| Intervalos de confianza al 95 % por bootstrap | `05_evaluacion_modelos.ipynb` |
| Severidad como porcentaje de área foliar afectada en CIELab | `backend/inference/leaf_analyzer.py` → `SeverityAnalyzer.analyze`; replicado en `07…` |
| Clasificación por píxel: sano, clorótico, necrótico, defoliado | `leaf_analyzer.py` (umbrales sobre L*, a*, b*) |
| La severidad se calcula solo si M1 clasifica la hoja como enferma | `backend/inference/diagnosis.py` (`p_diseased >= self._gate`) |
| Niveles de severidad (mínima, leve, moderada, severa, crítica) | `SeverityAnalyzer.level` |
| Exportación a TensorFlow Lite en float32 e int8 | `06_exportacion_tflite.ipynb` |
| Dataset representativo balanceado por clase para la cuantización | `_cls_samples()` en `06_exportacion_tflite.ipynb` |
| Configuración desplegada: M_seg int8, M1 int8, M2 float32 | `app/assets/models/`; `backend/inference/model_registry.py` |
| Verificación de equivalencia Keras ↔ TFLite | `06_exportacion_tflite.ipynb` |
| Integración de clima mediante Open-Meteo | `backend/services/climate.py` |
| Recomendaciones orientativas por enfermedad y nivel de severidad | `app/assets/data/tratamientos.json`; `backend/inference/diagnosis.py` |

---

## 3. Reproducción de los resultados

Orden de ejecución de los notebooks (Google Colab o Kaggle con GPU):

1. `01_preparacion_datos` → genera `splits/`.
2. `02_entrenamiento_segmentacion` → `model_seg.keras`. Debe ejecutarse antes que `03` y `04`,
   porque produce la hoja aislada que constituye su segunda entrada.
3. `03_entrenamiento_m1_estado_sanitario` y `04_entrenamiento_m2_patogeno`.
4. `05_evaluacion_modelos` → métricas de las tablas 1 y 2 del artículo.
5. `06_exportacion_tflite` → modelos desplegables y tabla 3.
6. `07_validacion_frente_a_experto` → comparación con el criterio experto.
7. `08`–`11` → baselines, ablación y verificación al presupuesto completo (tabla 5).
8. `12_calibracion_probabilidades` → ECE, MCE y Brier.
9. `13_evaluacion_variantes_exportadas` → tabla 4 (Keras, float32 e int8).

Los notebooks `08` a `11` guardan sus resultados por configuración y semilla, y omiten las
combinaciones ya calculadas, de modo que pueden reanudarse tras una desconexión.

---

## 4. Alcance de la evidencia

Las siguientes afirmaciones del artículo se apoyan en evidencia externa al repositorio y quedan
declaradas como limitaciones en el propio manuscrito:

- La validación frente al criterio experto empleó **60 hojas y un solo evaluador**, sin acuerdo
  inter-evaluador. La verdad de campo del patógeno proviene de la etiqueta del conjunto de datos,
  no de diagnóstico de laboratorio.
- **No existe validación con imágenes propias de Santa Cruz**; la aplicabilidad regional es
  plausible pero no demostrada.
- La **partición por fuente** no está disponible: la deduplicación evita duplicados exactos y
  cercanos, pero cada fuente está repartida entre entrenamiento y prueba.
- La medición de latencia y memoria corresponde a **un único dispositivo** (Xiaomi 2203129G,
  gama media) y se realizó con la herramienta oficial `benchmark_model` de TensorFlow Lite,
  fuera del repositorio.
- Los **umbrales CIELab son fijos** y requieren recalibración ante condiciones de captura distintas.
