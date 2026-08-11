# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
El proyecto sigue [versionado semántico](https://semver.org/lang/es/).

## [No publicado]

### Añadido

- Integración continua en GitHub Actions: análisis de la app Flutter, lint y formato del backend con Ruff, y validación de los notebooks.
- `scripts/validar_notebooks.py`: comprueba que los notebooks sean JSON válido, que sus celdas de código tengan sintaxis correcta y que no contengan comentarios.
- Plantillas de incidencia y de pull request, `.editorconfig` y configuración de Ruff en `pyproject.toml`.
- El notebook 07 exporta `validacion_experto_predicciones.csv`, un manifiesto por hoja con la procedencia de cada imagen y la predicción de cada etapa de la cascada.
- El notebook 13 evalúa también el segmentador en sus tres variantes (Keras, TFLite float32 e int8) sobre el 25 % reservado de las máscaras COCO, porque int8 es la variante desplegada. Produce `evaluacion_variantes_mseg.csv` y `.json`.
- `13_evaluacion_variantes_exportadas_kaggle.ipynb`: variante para Kaggle del notebook 13, con las celdas de cálculo idénticas a las de Colab.
- `scripts/verificar_paridad.py`: comprueba que la des-cuantización del backend reproduce exactamente la del intérprete de TensorFlow Lite.
- `scripts/desplegar_modelos.ps1`: coloca los artefactos del notebook 06 donde los esperan la app y el backend, creando los directorios que falten.

### Cambiado

- El notebook 07 calcula `patogeno_app` ejecutando la cascada real `M_seg → M1 → M2` en lugar de leerlo de un registro previo, y verifica que las hojas evaluadas por el experto no provengan del conjunto de entrenamiento.
- Las salidas cuantizadas se convierten con los parámetros reales del tensor, `(q − zero_point) × scale`, en el backend y en la aplicación. La fórmula anterior dividía entre 255 cuando la escala real es 1/256, un sesgo sistemático del 0.39 % en las confianzas mostradas.
- **La aplicación ya no calcula dosis, intervalos ni mezclas de productos.** La base de conocimiento pasa a `schema_version` 3.0 y entrega orientaciones de manejo cuya ejecución corresponde al profesional responsable, contra la etiqueta vigente y el registro del SENASAG.
- Las cinco clases de M2 se describen como **categorías operativas de afección foliar**, no como una taxonomía patogénica: la roya es un hongo pero se mantiene separada de las demás fúngicas, y plagas/insectos corresponde a daño por artrópodos.
- El componente de severidad atribuido a huecos internos pasa a llamarse **pérdida de tejido foliar** (`perforacion_pct`), en lugar de defoliación, que designa un fenómeno distinto.
- La documentación del proyecto se agrupa en `docs/`; las figuras del artículo pasan a `paper/figuras/` con las suplementarias anidadas.
- El backend adopta anotaciones de tipo de PEP 604 (`X | None`) y ordenación de importaciones conforme a Ruff.
- El recall de hoja del segmentador pasa de 0.977 a **0.974**. El suavizado `+1e-6` del notebook `05` convertía en acierto perfecto (`1e-6/1e-6 = 1.0`) una imagen cuya máscara de referencia estaba vacía; con 368 imágenes eso inflaba la media en exactamente 1/368. Dice e IoU no se veían afectados, porque en ese caso degenerado ambos dan ~0 con y sin suavizado. Ahora esas imágenes se descartan y el notebook informa cuántas.
- Las métricas del segmentador se citan desde `evaluacion_variantes_mseg.csv`, que evalúa las tres variantes exportadas sobre el mismo conjunto reservado, en lugar de `mseg_test_metrics.json`.

### Eliminado

- `DoseCalculator` y `TreatmentDose`, que calculaban cantidades de producto por hectárea.
- Los widgets `SeverityPanel` y `DiseaseSummaryBanner`, que no se referenciaban desde ninguna pantalla.

## [1.0.0] — 2026-08-09

Versión que acompaña al artículo *Detección móvil de enfermedades y severidad foliar en soya*.

### Añadido

- Cascada de tres modelos: segmentación hoja–fondo (U-Net ResNet50) y dos clasificadores de doble entrada, estado sanitario (EfficientNetB1) y categoría de afección foliar en cinco clases (EfficientNetB0).
- Estimación de severidad foliar por reglas de color en CIELab, con desagregación en clorosis, necrosis y pérdida de tejido foliar.
- Aplicación Flutter con inferencia local sin conexión y recomendaciones ajustadas al clima mediante Open-Meteo.
- Backend FastAPI opcional con los mismos modelos, distribuido en Docker.
- Trece notebooks de reproducción, de la preparación de datos a la evaluación de las variantes exportadas.
- Conjunto de datos curado y modelos entrenados publicados en Hugging Face; resultados numéricos en el release `v1.0-paper`.

[No publicado]: https://github.com/alejandroramirezucb/glycine-vision-dss/compare/v1.0-paper...HEAD
[1.0.0]: https://github.com/alejandroramirezucb/glycine-vision-dss/releases/tag/v1.0-paper
