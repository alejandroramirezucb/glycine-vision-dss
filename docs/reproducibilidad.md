# Reproducibilidad

Procedimiento completo para reconstruir el sistema desde cero: datos, entrenamiento, exportación y despliegue. Para saber de dónde sale cada cifra publicada, véase [`trazabilidad.md`](trazabilidad.md).

## Requisitos

| Entorno | Uso | Requisitos |
|---|---|---|
| Google Colab o Kaggle | Entrenamiento y evaluación | GPU (T4 o superior), unos 4 días de cómputo acumulado para el ciclo completo con ablación |
| Local | App, backend y despliegue | Python 3.12, Flutter 3.x, Git LFS |

Las dependencias de los notebooks están en `training/requirements.txt`; las del backend, en `backend/requirements.txt`.

## Datos

El conjunto curado se publica en [Hugging Face](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset). El notebook `01` lo descarga, pero puede obtenerse directamente:

```python
from huggingface_hub import snapshot_download

snapshot_download(repo_id="alejandroramirezucb/soybean_image_dataset",
                  repo_type="dataset", local_dir="./data")
```

El notebook `01` aplica los filtros de calidad, la deduplicación por MD5 y hash perceptual, y las particiones, y deja el resultado en `splits/`. Procesa el conjunto de entrenamiento antes que el de prueba para que la deduplicación no elimine imágenes de prueba en favor de duplicados de entrenamiento.

Para la validación frente al experto se requiere además `splits/severity_val/`, con las imágenes evaluadas agrupadas por clase real y un `labels.csv` que contenga `file_name`, `severidad_experto` y `patogeno_experto`. Las columnas de la aplicación **no** se registran ahí: el notebook `07` las calcula ejecutando la cascada.

## Orden de ejecución

El grafo de dependencias tiene una sola restricción fuerte, pero es determinante:

```
01 ──> 02 ──┬──> 03 ──┬──> 05 ──> 06 ──> 13
            │         │
            ├──> 04 ──┘
            │
            └──> 07
                 08 ──> 09 ──> 10 ──> 11
                 12
```

**El segmentador (`02`) debe entrenarse antes que los clasificadores.** M1 y M2 reciben como segunda entrada la hoja aislada que produce ese modelo; sin él, los notebooks `03` y `04` fallan al arrancar.

Los notebooks `08` a `11` son costosos: una corrida completa de ablación ocupa alrededor de un día de GPU. Guardan resultados por configuración y semilla en un CSV compartido y omiten las combinaciones ya calculadas, de modo que una desconexión de Colab no obliga a repetir el trabajo. Conviene apuntar ese CSV a Google Drive para que sobreviva al reinicio del entorno.

## Notebooks

| Notebook | Produce |
|---|---|
| `01_preparacion_datos` | `splits/` |
| `02_entrenamiento_segmentacion` | `model_seg.keras`, `M_seg_curves.png` |
| `03_entrenamiento_m1_estado_sanitario` | `model1_binary.keras`, `class_indices_model1_binary.json` |
| `04_entrenamiento_m2_patogeno` | `model2_pathogen.keras`, `class_indices_model2_pathogen.json` |
| `05_evaluacion_modelos` | `training_metrics.json`, matrices de confusión |
| `06_exportacion_tflite` | `*.tflite` en float32 e int8, `model_metadata.json`, `labels_*.txt` |
| `07_validacion_frente_a_experto` | `comparacion_app_vs_experto.json`, `validacion_experto_predicciones.csv` |
| `08_diagnostico_baselines` | `diagnostico_m2.csv` |
| `09_ablacion_presupuesto_reducido` | `baselines_m2.csv`, `ablation_m2.csv` |
| `10_verificacion_presupuesto_completo` | `verificacion_full_m2.csv` |
| `11_ablacion_presupuesto_completo` | `ablation_full_m2.csv` |
| `12_calibracion_probabilidades` | `calibracion.json`, `calibracion.csv`, diagramas de confiabilidad |
| `13_evaluacion_variantes_exportadas` | `evaluacion_variantes.csv`, `.json`, `evaluacion_variantes_mseg.csv`, `.json` |

El notebook `13` tiene además una variante para Kaggle, `13_evaluacion_variantes_exportadas_kaggle.ipynb`. Sus
siete celdas de cálculo son **byte a byte idénticas** a las de la versión de Colab; solo difieren la celda de
instalación y la de descubrimiento de rutas, porque Kaggle monta los datos en `/kaggle/input/` en modo solo
lectura y escribe en `/kaggle/working/`. Hay que adjuntar en *Add Input* la carpeta `splits/` (con `test/`,
`masks/` y `masks_soycotton/`) y los nueve artefactos de modelo; la celda de descubrimiento los busca de forma
recursiva y aborta indicando cuáles faltan.

## Máscaras de segmentación

El segmentador se entrena con dos conjuntos de máscaras COCO que el notebook `02` fusiona en una única clase *hoja*:

| Origen | Ruta esperada |
|---|---|
| Máscaras propias anotadas en Roboflow | `training/splits/masks/` con `_annotations.coco.json` |
| Conjunto SoyCotton | `training/splits/masks_soycotton/annotations/` y `.../images/` |

La celda de descarga del notebook `01` reproduce esa estructura.

## Despliegue de los modelos

Tras ejecutar el notebook `06`, los artefactos quedan en `training/outputs/`. Este script los coloca donde los esperan la aplicación y el backend, creando los directorios que falten:

```powershell
pwsh scripts/desplegar_modelos.ps1
```

Falla de entrada, sin copiar nada a medias, si algún artefacto no está en el origen. Acepta `-Origen` para leer desde otra carpeta.

| Artefacto | Destino en la app | Destino en el backend |
|---|---|---|
| `model_seg_int8.tflite` | `seg/model_seg.tflite` | `segmentation/model_int8.tflite` |
| `model_seg.tflite` | — | `segmentation/model.tflite` |
| `model1_int8.tflite` | `hs/model.tflite` | `health/model_int8.tflite` |
| `model1.tflite` | — | `health/model.tflite` |
| `model2.tflite` | `pd/model_unquant.tflite` | `disease/model.tflite` |
| `model2_int8.tflite` | — | `disease/model_int8.tflite` |

La asignación no es arbitraria. El segmentador y M1 se despliegan en **int8**, porque la cuantización les cuesta 0.005 de F1 o menos. M2 se despliega en **float32**, porque perdía 0.040 de F1 al cuantizarse: un coste inaceptable para la etapa que decide la categoría de afección. Esa decisión se sostiene en el notebook `13`.

`app/assets/models/` se versiona mediante Git LFS, así que llega con el clon. **`models/` no se versiona**, porque son 270 MB de los que el backend solo carga una parte: hay que ejecutar el script tras clonar. Si falta, `python server.py` aborta al construir el registro:

```
ValueError: Could not open '...\models\health\model_int8.tflite'.
```

## Medición en dispositivo

Latencia y memoria se midieron fuera del repositorio con la herramienta oficial de TensorFlow Lite:

```bash
adb push benchmark_model /data/local/tmp/
adb push model_seg_int8.tflite /data/local/tmp/
adb shell chmod +x /data/local/tmp/benchmark_model
adb shell "/data/local/tmp/benchmark_model \
  --graph=/data/local/tmp/model_seg_int8.tflite \
  --num_threads=4 --num_runs=50 --warmup_runs=10 \
  --report_peak_memory_footprint=true"
```

De la salida se leen `Inference (avg)` en microsegundos y `Overall peak memory footprint` en megabytes.

## Qué esperar al reejecutar

El entrenamiento es determinista en la partición (semilla 42) pero no en el resultado: la no determinación de cuDNN y el orden de reducción en GPU introducen variación entre corridas. La desviación estándar observada entre semillas en el estudio de ablación es de unos **0.005 de F1**, y conviene interpretar cualquier diferencia menor que eso como ruido, no como efecto.
