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

Conjunto curado de imágenes de hojas de soya (*Glycine max*) para tres tareas: clasificación del estado sanitario (sana o enferma), clasificación de la categoría de afección foliar en cinco clases operativas (bacterianas, fúngicas, roya, virales y plagas o insectos) y segmentación hoja–fondo.

Se construyó consolidando ocho fuentes públicas, aplicando filtros de calidad y deduplicación, y muestreando aleatoriamente entre las imágenes con mejores criterios de visibilidad. Es el conjunto con el que se entrenó **Glycine Vision**.

> **Antes de reutilizarlo:** este conjunto deriva de fuentes con licencias mixtas, una de ellas no comercial y dos sin licencia declarada. Véase [Licencia](#licencia).

## Estructura

```
Train/
  clasificacion_binaria/    soya_sana/ · soya_enferma/
  clasificacion_patogeno/   bacterianas/ · fungicas/ · plagas_insectos/ · roya/ · virales/
Test/
  clasificacion_binaria/    100 imágenes por clase
  clasificacion_patogeno/    70 imágenes por clase
Masks/                      Máscaras de hoja propias, anotadas en Roboflow (formato COCO)
Masks_Soycotton/            Máscaras del conjunto SoyCotton (formato COCO)
```

`Train/` se reparte en entrenamiento y validación (80/20, semilla 42) durante la preparación. `Test/` no interviene en ninguna etapa de entrenamiento. Las dos carpetas de máscaras se fusionan como una única clase *hoja* para entrenar el segmentador.

## Uso

```python
from huggingface_hub import snapshot_download

snapshot_download(repo_id="alejandroramirezucb/soybean_image_dataset",
                  repo_type="dataset", local_dir="./data")
```

El flujo completo de preparación (filtros, deduplicación y particiones) está en el notebook `01_preparacion_datos.ipynb` del [repositorio del proyecto](https://github.com/alejandroramirezucb/glycine-vision-dss).

## Fuentes

Este conjunto **deriva** de datasets públicos de investigación. El crédito corresponde a sus autores originales.

### Con cita formal

| Fuente | Referencia | Enlace |
|---|---|---|
| ASDID (Auburn University) | Bevers et al. (2022) | [10.1016/j.compag.2022.107449](https://doi.org/10.1016/j.compag.2022.107449) |
| MH-SoyaHealthVision | Shinde & Attar (2024) | [10.17632/hkbgh5s3b7.1](https://doi.org/10.17632/hkbgh5s3b7.1) |
| India Soybean Dataset | Kotwal et al. (2023) | [10.2139/ssrn.4644426](https://doi.org/10.2139/ssrn.4644426) |
| SoyNet | Rajput et al. (2023) | [10.1016/j.dib.2023.109447](https://doi.org/10.1016/j.dib.2023.109447) |
| Cotton & Soybean Leaf Dataset | Bhujade et al. (2025) | [10.1111/jph.70051](https://doi.org/10.1111/jph.70051) |
| SoyCotton (máscaras de segmentación) | Segreto et al. (2026) | [10.1038/s41597-026-07092-8](https://doi.org/10.1038/s41597-026-07092-8) |

### Fuentes abiertas

| Fuente | Licencia | Correspondencia |
|---|---|---|
| [PlantVillage](https://www.kaggle.com/datasets/abdallahalidev/plantvillage-dataset), subconjunto de soya sana | CC BY-NC-SA 4.0 | Hughes & Salathé (2015) |
| [Soybean leaf dataset for disease classification](https://www.kaggle.com/datasets/vaishaligbhujade/soybean-leaf-dataset-for-disease-classification) | No especificada | Bhujade et al. (2025) |
| [Soybean diseased leaf dataset](https://www.kaggle.com/datasets/sivm205/soybean-diseased-leaf-dataset) | No especificada | — |
| [Soybean leaf dataset](https://www.kaggle.com/datasets/maeloisamignoni/soybeanleafdataset), subconjunto de plagas | No especificada | *Caterpillar*, *Diabrotica speciosa* y sana |
| [Soybean dataset (Mendeley)](https://data.mendeley.com/datasets/w2r855hpx8/2) | CC BY 4.0 | SoyNet, Rajput et al. (2023) |

## Curación

1. **Filtros de calidad.** Apertura válida, formato RGB y resolución mínima de 224 × 224 px.
2. **Deduplicación.** Hash exacto (MD5) y hash perceptual (pHash), con registro compartido por tarea. El conjunto de entrenamiento se procesa **antes** que el de prueba, de modo que ante un duplicado se conserve la imagen de prueba y se descarte la de entrenamiento, nunca al revés.
3. **Selección.** Muestreo aleatorio con semilla fija (42) entre las imágenes con mejores criterios de visibilidad.
4. **Particiones.** Entrenamiento y validación al 80/20, más un conjunto de prueba independiente (100 imágenes por clase para estado sanitario, 70 por clase para la categoría de afección). Para segmentación, partición 75/25 con 15 % de validación.

## Limitaciones

- **No existe partición por procedencia.** Imágenes distintas de una misma planta, sesión o condición de captura pueden quedar repartidas entre entrenamiento y prueba. Las métricas obtenidas con este conjunto deben interpretarse como **desempeño interno del corpus**, no como evidencia de generalización a dominios nuevos. Es la limitación más importante de este conjunto.
- **No incluye imágenes de Santa Cruz (Bolivia)**, la región a la que apunta el proyecto. La aplicabilidad regional es plausible pero no demostrada.
- **La verdad de campo de la categoría proviene de las etiquetas de las fuentes originales**, no de diagnóstico de laboratorio.
- **Las cinco clases son categorías operativas, no una taxonomía patogénica.** La roya (*Phakopsora pachyrhizi*) es un hongo pero se mantiene separada de las demás fúngicas por su relevancia epidemiológica y su signo característico; plagas/insectos corresponde a daño por artrópodos, no a un patógeno.
- Los umbrales de calidad y el muestreo aleatorio pueden introducir sesgos de selección.

## Licencia

Este conjunto **deriva** de fuentes con condiciones mixtas:

- El subconjunto de soya sana procede de PlantVillage, bajo **CC BY-NC-SA 4.0**. La cláusula no comercial y la de compartir igual se propagan al conjunto combinado.
- Dos fuentes de Kaggle (`sivm205` y `maeloisamignoni`) **no declaran licencia**.

En consecuencia, la licencia del conjunto **no puede determinarse con certeza y, como mínimo, excluye el uso comercial**; se declara como `unknown`. Se comparte con fines de investigación académica y se solicita atribución a los autores originales. Antes de cualquier reutilización, verifica la licencia de cada fuente en su página de origen.

Esta licencia aplica **solo a los datos**. El código del proyecto se distribuye bajo MIT y el manuscrito bajo CC BY 4.0.

## Cita

> Jaldín Torrico, E., & Ramírez Vallejos, A. (2026c). *Soybean image dataset* [Conjunto de datos]. Hugging Face. https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset
