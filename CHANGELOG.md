# Registro de cambios

Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/).
El proyecto sigue [versionado semántico](https://semver.org/lang/es/).

## [No publicado]

### Añadido

- Integración continua en GitHub Actions: análisis de la app Flutter, lint y formato del backend con Ruff, y validación de los notebooks.
- `scripts/validar_notebooks.py`: comprueba que los notebooks sean JSON válido, que sus celdas de código tengan sintaxis correcta y que no contengan comentarios.
- Plantillas de incidencia y de pull request, `.editorconfig` y configuración de Ruff en `pyproject.toml`.
- El notebook 07 exporta `validacion_experto_predicciones.csv`, un manifiesto por hoja con la procedencia de cada imagen y la predicción de cada etapa de la cascada.

### Cambiado

- El notebook 07 calcula `patogeno_app` ejecutando la cascada real `M_seg → M1 → M2` en lugar de leerlo de un registro previo, y verifica que las hojas evaluadas por el experto no provengan del conjunto de entrenamiento.
- La documentación del proyecto se agrupa en `docs/`; las figuras del artículo pasan a `paper/figuras/` con las suplementarias anidadas.
- El backend adopta anotaciones de tipo de PEP 604 (`X | None`) y ordenación de importaciones conforme a Ruff.

## [1.0.0] — 2026-08-09

Versión que acompaña al artículo *Detección móvil de enfermedades y severidad foliar en soya*.

### Añadido

- Cascada de tres modelos: segmentación hoja–fondo (U-Net ResNet50) y dos clasificadores de doble entrada, estado sanitario (EfficientNetB1) y patógeno en cinco categorías (EfficientNetB0).
- Estimación de severidad foliar por reglas de color en CIELab, con desagregación en clorosis, necrosis y defoliación.
- Aplicación Flutter con inferencia local sin conexión y recomendaciones ajustadas al clima mediante Open-Meteo.
- Backend FastAPI opcional con los mismos modelos, distribuido en Docker.
- Trece notebooks de reproducción, de la preparación de datos a la evaluación de las variantes exportadas.
- Conjunto de datos curado y modelos entrenados publicados en Hugging Face; resultados numéricos en el release `v1.0-paper`.

[No publicado]: https://github.com/alejandroramirezucb/glycine-vision-dss/compare/v1.0-paper...HEAD
[1.0.0]: https://github.com/alejandroramirezucb/glycine-vision-dss/releases/tag/v1.0-paper
