---
license: unknown
pretty_name: Soybean Image Dataset
task_categories:
- image-classification
- image-segmentation
language:
- es
tags:
- agriculture
- plant-disease
- soybean
- computer-vision
- leaf
size_categories:
- 10K<n<100K
---

# Soybean Image Dataset

Conjunto de datos curado de hojas de soya (*Glycine max*) para (1) clasificación del estado sanitario
(sana/enferma), (2) clasificación del patógeno en cinco categorías (bacterianas, fúngicas, roya, virales,
plagas/insectos) y (3) segmentación hoja–fondo. Se construyó consolidando varios conjuntos públicos, aplicando
filtros de calidad y deduplicación, y seleccionando aleatoriamente entre las imágenes con mejores criterios de
visibilidad. Es el dataset usado para entrenar el sistema **Glycine Vision**.

## Fuentes de origen

Este conjunto **deriva** de datasets públicos de investigación. El crédito corresponde a sus autores originales; se
listan aquí todas las fuentes.

**Con cita formal:**

| Fuente | Referencia | Enlace |
|---|---|---|
| ASDID (Auburn University) | Bevers et al. (2022) | https://doi.org/10.1016/j.compag.2022.107449 |
| MH-SoyaHealthVision | Shinde & Attar (2024) | https://doi.org/10.17632/hkbgh5s3b7.1 |
| India Soybean Dataset | Kotwal et al. (2023) | https://doi.org/10.2139/ssrn.4644426 |
| SoyNet | Rajput et al. (2023) | https://doi.org/10.1016/j.dib.2023.109447 |
| Cotton & Soybean Leaf Dataset | Bhujade et al. (2025) | https://doi.org/10.1111/jph.70051 |
| SoyCotton (máscaras de segmentación) | Segreto et al. (2026) | https://doi.org/10.1038/s41597-026-07092-8 |

**Fuentes abiertas (Kaggle / Mendeley):**

| Fuente | Enlace | Licencia / correspondencia |
|---|---|---|
| PlantVillage (subconjunto soya sana) | https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset | CC BY-NC-SA 4.0 — corresponde a Hughes & Salathé (2015) |
| Soybean leaf dataset for disease classification | https://www.kaggle.com/datasets/vaishaligbhujade/soybean-leaf-dataset-for-disease-classification | Unknown (Kaggle) — corresponde a Bhujade et al. (2025) |
| Soybean diseased leaf dataset | https://www.kaggle.com/datasets/sivm205/soybean-diseased-leaf-dataset | Unknown (Kaggle) |
| Soybean leaf dataset (plagas) | https://www.kaggle.com/datasets/maeloisamignoni/soybeanleafdataset | Unknown (Kaggle) — subconjunto de plagas: Caterpillar + Diabrotica speciosa + sana |
| Soybean dataset (Mendeley) | https://data.mendeley.com/datasets/w2r855hpx8/2 | CC BY 4.0 — corresponde a SoyNet, Rajput et al. (2023) |

## Proceso de curación

1. **Filtros de calidad**: apertura válida, formato RGB, resolución mínima 224 × 224 px.
2. **Deduplicación**: hash exacto (MD5) y hash perceptual (pHash) con registro compartido por tarea, procesando el
   conjunto de entrenamiento antes que el de prueba para evitar fuga entrenamiento–prueba.
3. **Selección**: muestreo aleatorio (semilla fija = 42) entre las imágenes con mejores criterios de visibilidad.
4. **Particiones**: entrenamiento/validación 80/20 y un test independiente (100 imágenes/clase para estado sanitario,
   70/clase para patógeno). Para segmentación: partición 75/25 con 15 % de validación.

## Estructura

```
Train/
  clasificacion_binaria/    soya_sana/ · soya_enferma/
  clasificacion_patogeno/   bacterianas/ · fungicas/ · plagas_insectos/ · roya/ · virales/
Test/
  clasificacion_binaria/    conjunto independiente (100 imágenes por clase)
  clasificacion_patogeno/   conjunto independiente (70 imágenes por clase)
Masks/                      máscaras de hoja propias, anotadas en Roboflow (formato COCO)
Masks_Soycotton/            máscaras del conjunto SoyCotton (formato COCO)
```

`Train/` se reparte en entrenamiento y validación (80/20, semilla 42) durante la preparación; `Test/` no se
utiliza en ninguna etapa de entrenamiento. Las dos carpetas de máscaras se fusionan como una única clase *hoja*
para entrenar el segmentador.

## Uso

```python
from huggingface_hub import snapshot_download

snapshot_download(repo_id="alejandroramirezucb/soybean_image_dataset",
                  repo_type="dataset", local_dir="./data")
```

El flujo completo de preparación (filtros, deduplicación y particiones) está en el notebook
`01_preparacion_datos.ipynb` del [repositorio del proyecto](https://github.com/alejandroramirezucb/glycine-vision-dss).

## Licencia

Conjunto **derivado** de fuentes con condiciones mixtas. El subconjunto de soya sana proveniente de PlantVillage
está bajo **CC BY-NC-SA 4.0** (no comercial, compartir igual), restricción que se propaga al conjunto combinado.
Además, dos fuentes de Kaggle (`sivm205` y `maeloisamignoni`) tienen **licencia no especificada**. En consecuencia,
la licencia del conjunto **no puede determinarse con certeza y, como mínimo, excluye el uso comercial**; se declara
como `unknown`. Se comparte únicamente con fines de investigación académica y se solicita **atribución** a los
autores originales. Antes de cualquier reutilización, verifique la licencia de cada fuente en su página de origen.

Esta licencia aplica **solo a los datos**. El código del proyecto se distribuye bajo licencia MIT y el manuscrito
bajo CC BY 4.0; véase la sección de licencias del repositorio.

## Cita recomendada

> Jaldín Torrico, E., & Ramírez Vallejos, A. (2026c). *Soybean image dataset* [Conjunto de datos]. Hugging Face. https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset

## Limitaciones

- No incluye imágenes propias de Santa Cruz (Bolivia); la aplicabilidad regional es plausible pero no demostrada.
- La verdad de campo del patógeno proviene de las etiquetas de las fuentes, no de diagnóstico de laboratorio.
- **No existe partición por procedencia**: imágenes distintas de una misma planta, sesión o condición de captura
  pueden quedar repartidas entre entrenamiento y prueba, por lo que las métricas obtenidas con este conjunto deben
  interpretarse como desempeño interno del corpus y no como evidencia de generalización a dominios nuevos.
- Los umbrales de calidad y la selección aleatoria pueden introducir sesgos de muestreo.
