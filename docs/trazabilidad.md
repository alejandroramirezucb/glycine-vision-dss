# Trazabilidad

Este documento enlaza cada afirmación cuantitativa y metodológica del manuscrito con el código que la produce y con el archivo de resultados que la respalda. Su propósito es que cualquier revisor pueda verificar el origen de cada número **sin ejecutar el proyecto completo**.

Los notebooks están en `training/notebooks/`, sus salidas en `training/outputs/` y el código de inferencia en `backend/inference/`. Los archivos de resultados se publican en el [release `v1.0-paper`](https://github.com/alejandroramirezucb/glycine-vision-dss/releases/tag/v1.0-paper); el conjunto de datos y los modelos, en Hugging Face ([datos](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset), [modelos](https://huggingface.co/alejandroramirezucb/glycine-vision-models)).

## 1. Resultados cuantitativos

Las métricas del segmentador provienen de `evaluacion_variantes_mseg.csv`, que evalúa las tres variantes exportadas sobre el mismo conjunto reservado. Sustituye a `mseg_test_metrics.json`, cuyo recall estaba inflado por una imagen con máscara de referencia vacía (véase el registro de cambios).


| Afirmación | Valor | Notebook | Evidencia |
|---|---|---|---|
| Recall de hoja del segmentador | 0.974 | `13_evaluacion_variantes_exportadas` | `evaluacion_variantes_mseg.csv` → fila `Keras` |
| Dice del segmentador | 0.885 | `13_evaluacion_variantes_exportadas` | `evaluacion_variantes_mseg.csv` → fila `Keras` |
| IoU del segmentador | 0.808 | `13_evaluacion_variantes_exportadas` | `evaluacion_variantes_mseg.csv` → fila `Keras` |
| Exactitud de M1 con IC 95 % | 0.980 (0.960–0.995) | `05_evaluacion_modelos` | `training_metrics.json` → `m1.accuracy`, `m1.ci95.accuracy` |
| Recall de M1 en la clase enferma | 1.000 | `05_evaluacion_modelos` | `training_metrics.json` → `m1.recall_enferma` |
| Exactitud de M2 con IC 95 % | 0.969 (0.949–0.986) | `05_evaluacion_modelos` | `training_metrics.json` → `m2.accuracy`, `m2.ci95.accuracy` |
| F1 macro de M2 | 0.968 | `05_evaluacion_modelos` | `training_metrics.json` → `m2.f1_macro` |
| F1 por clase de M2 | 0.950 / 0.920 / 0.986 / 0.986 / 1.000 | `05_evaluacion_modelos` | `training_metrics.json` → `m2.per_class_f1` |
| Severidad frente al experto: r, CCC, MAE, RMSE | 0.953, 0.923, 6.5 %, 8.5 % | `07_validacion_frente_a_experto` | `comparacion_app_vs_experto.json` → `severidad` |
| Bland-Altman: sesgo y límites de acuerdo | −5.4 %, [−18.3, 7.5] | `07_validacion_frente_a_experto` | `comparacion_app_vs_experto.json` → `severidad.bias`, `loa_low`, `loa_high` |
| Categoría de afección, app frente a experto, y McNemar | 0.917 frente a 0.883; p = 0.754 | `07_validacion_frente_a_experto` | `comparacion_app_vs_experto.json` → `patogeno` |
| Predicción por hoja de la validación experta | 60 hojas, 10 por clase | `07_validacion_frente_a_experto` | `validacion_experto_predicciones.csv` |
| Costo computacional: parámetros, MACs, tamaño | Tabla 3 | `06_exportacion_tflite` | `model_metadata.json` y tamaño de los `.tflite` |
| Variantes exportadas de M1 y M2: Keras, float32, int8 | Tabla 4 | `13_evaluacion_variantes_exportadas` | `evaluacion_variantes.csv`, `.json` |
| Variantes exportadas del segmentador: recall de hoja, Dice, IoU | Tabla 5 | `13_evaluacion_variantes_exportadas` | `evaluacion_variantes_mseg.csv`, `.json` |
| Ablación por componente, media ± DE, 3 semillas | Tabla 6 | `11_ablacion_presupuesto_completo` | `ablation_full_m2.csv` |
| Verificación frente al baseline de una entrada, 1 semilla | 0.980 frente a 0.963 | `10_verificacion_presupuesto_completo` | `verificacion_full_m2.csv` |
| Calibración: ECE, MCE, Brier | M1 0.011 / 0.63 / 0.016; M2 0.039 / 0.55 / 0.049 | `12_calibracion_probabilidades` | `calibracion.json`, `calibracion.csv` |
| Latencia y memoria en dispositivo | 126 / 19 / 12 ms; 120 / 54 / 40 MB | Medición externa con `benchmark_model` de TFLite vía `adb` sobre un Xiaomi 2203129G | Salida de consola del benchmark |

## 2. Afirmaciones metodológicas

| Afirmación | Implementación |
|---|---|
| U-Net con codificador ResNet50, entrada 256 × 256, dos clases | `02_entrenamiento_segmentacion` |
| Posprocesamiento por mayor componente conexo | `backend/inference/segmenter.py` → `_largest_component` |
| M1: EfficientNetB1, 240 × 240, salida sigmoide | `03_entrenamiento_m1_estado_sanitario` |
| M2: EfficientNetB0, 224 × 224, softmax de cinco clases | `04_entrenamiento_m2_patogeno` |
| Doble entrada con codificador compartido | `build_dual()` en `03` y `04`; `backend/inference/classifier.py` |
| La hoja aislada proviene del segmentador, no de umbrales HSV | `mseg_mask()` en `03` y `04`; `backend/inference/diagnosis.py` |
| Shades-of-Gray, Minkowski p = 6, ganancia en [0.6, 1.6] | `chromatic_normalize()` en `02`–`05` y `07`; `backend/inference/preprocessor.py` |
| Misma normalización en entrenamiento e inferencia | `training/notebooks/*` y `backend/inference/preprocessor.py` |
| Pérdida focal binaria con balanceo en M1 | `03_entrenamiento_m1_estado_sanitario` |
| Entropía cruzada con suavizado de etiquetas en M2 | `04_entrenamiento_m2_patogeno` (`LABEL_SMOOTH = 0.05`) |
| Promediado exponencial de pesos | `EMACallback` en `03`, `04`, `09` y `11` |
| Deduplicación por MD5 y pHash sin fuga entre particiones | `deduplicar_y_limpiar()` en `01_preparacion_datos` |
| Filtros de calidad: apertura válida, RGB, mínimo 224 × 224 px | `validar()` en `01_preparacion_datos` |
| Semilla fija 42 y partición 80/20 | `01_preparacion_datos` (`train_test_split(..., random_state=42)`) |
| Segmentación: partición 75/25 con 15 % de validación | `02_entrenamiento_segmentacion` (`TEST_FRACTION`, `VAL_FRACTION`) |
| Intervalos de confianza al 95 % por bootstrap | `05_evaluacion_modelos` |
| Severidad como porcentaje de área foliar afectada en CIELab | `backend/inference/leaf_analyzer.py` → `SeverityAnalyzer.analyze`; replicado en `07` |
| Clasificación por píxel: sano, clorótico, necrótico, con pérdida de tejido | `leaf_analyzer.py`, umbrales sobre L\*, a\* y b\* |
| La severidad y M2 se activan solo si M1 clasifica la hoja como enferma | `backend/inference/diagnosis.py` (`p_diseased >= self._gate`); replicado en `07` |
| Niveles de severidad: mínima, leve, moderada, severa, crítica | `SeverityAnalyzer.level` (5 / 15 / 35 / 60 %) |
| Exportación a TensorFlow Lite en float32 e int8 | `06_exportacion_tflite` |
| Dataset representativo balanceado por clase para la cuantización | `_cls_samples()` en `06_exportacion_tflite` |
| Configuración desplegada: segmentador int8, M1 int8, M2 float32 | `app/assets/models/`; `backend/inference/model_registry.py` |
| Verificación de equivalencia entre Keras y TensorFlow Lite | `06_exportacion_tflite` |
| Integración climática mediante Open-Meteo | `backend/services/climate.py`; `app/lib/infrastructure/open_meteo_client.dart` |
| El clima desplaza el nivel de severidad un escalón | `app/lib/infrastructure/climate_severity_adjuster.dart` |
| El clima adelanta o retrasa la ventana de aparición | `app/lib/infrastructure/onset_estimator_impl.dart` |
| Verificación de incompatibilidades entre productos | `app/lib/infrastructure/incompatibility_checker.dart`; `app/assets/data/tratamientos.json` |
| Des-cuantización con `scale` y `zero_point` reales del tensor | `backend/inference/quantization.py`; `app/lib/infrastructure/quantization.dart` |
| Paridad de des-cuantización entre backend y el intérprete de referencia | `scripts/verificar_paridad.py` (desvío 0.000e+00 en los tres modelos) |
| Paridad de des-cuantización en la aplicación | `app/test/quantization_test.dart` (4 pruebas contra los valores del intérprete) |
| El sistema no calcula dosis, intervalos ni mezclas | `app/assets/data/tratamientos.json` (`schema_version` 3.0); `app/lib/infrastructure/treatment_repo.dart` |

## 3. Reproducción

Orden de ejecución en Google Colab o Kaggle con GPU:

1. `01_preparacion_datos` genera `splits/`.
2. `02_entrenamiento_segmentacion` produce `model_seg.keras`. **Debe ejecutarse antes que `03` y `04`**, porque genera la hoja aislada que constituye su segunda entrada.
3. `03_entrenamiento_m1_estado_sanitario` y `04_entrenamiento_m2_patogeno`.
4. `05_evaluacion_modelos` produce las tablas 1 y 2.
5. `06_exportacion_tflite` produce los modelos desplegables y la tabla 3.
6. `07_validacion_frente_a_experto` ejecuta la cascada completa sobre las hojas evaluadas por el experto.
7. `08`–`11` producen baselines, ablación y verificación al presupuesto completo (tabla 5).
8. `12_calibracion_probabilidades` produce ECE, MCE y Brier.
9. `13_evaluacion_variantes_exportadas` produce la tabla 4.

Los notebooks `08` a `11` guardan sus resultados por configuración y semilla, y omiten las combinaciones ya calculadas: pueden reanudarse tras una desconexión.

El detalle operativo, incluido el despliegue de los modelos al backend y a la app, está en [`reproducibilidad.md`](reproducibilidad.md).

## 4. Alcance de la evidencia

Estas afirmaciones se apoyan en evidencia externa al repositorio y están declaradas como limitaciones en el propio manuscrito:

- La validación experta empleó **60 hojas y un solo evaluador**, sin acuerdo inter-evaluador. La verdad de campo de la categoría de afección proviene de la etiqueta del conjunto de datos, no de diagnóstico de laboratorio.
- **No hay validación con imágenes propias de Santa Cruz**; la aplicabilidad regional es plausible pero no demostrada.
- **No existe partición por procedencia**. La deduplicación evita duplicados exactos y cercanos, pero cada fuente está repartida entre entrenamiento y prueba, por lo que las métricas reflejan desempeño interno del corpus.
- La medición de latencia y memoria corresponde a **un único dispositivo** y se realizó con la herramienta oficial `benchmark_model` de TensorFlow Lite, fuera del repositorio.
- Los **umbrales CIELab son fijos**: están calibrados sobre las condiciones de captura del corpus y requieren reajuste ante condiciones distintas.
