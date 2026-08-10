# Guía de contribución

Gracias por el interés en Glycine Vision DSS. Este documento describe cómo preparar el entorno, qué convenciones sigue el código y qué se espera de un pull request.

Antes de empezar, lee el [Código de Conducta](CODE_OF_CONDUCT.md). Para vulnerabilidades de seguridad, sigue [SECURITY.md](SECURITY.md) en lugar de abrir una incidencia pública.

## Antes de escribir código

Revisa las [incidencias abiertas](https://github.com/alejandroramirezucb/glycine-vision-dss/issues) por si la propuesta ya existe. Para cambios de alcance amplio (una arquitectura distinta, una clase de patógeno nueva, un cambio en el contrato de la API) abre una incidencia primero: es más barato discutir el enfoque que descartar una implementación terminada.

## Preparar el entorno

El repositorio usa Git LFS para los modelos `.tflite`. Instálalo **antes** de clonar o los archivos llegarán como punteros de texto.

```bash
git lfs install
git clone https://github.com/alejandroramirezucb/glycine-vision-dss.git
cd glycine-vision-dss
```

### Aplicación Flutter

```bash
cd app
flutter pub get
flutter analyze
flutter run -d <id_del_dispositivo>
```

### Backend

```bash
cd backend
python -m venv .venv && .venv/Scripts/Activate.ps1   # Linux y macOS: source .venv/bin/activate
pip install -r requirements.txt
python server.py
```

El backend carga los modelos desde `MODELS_DIR` (por defecto `../models`), una carpeta que no se versiona. El procedimiento para generarla desde `training/outputs/` está en [`docs/reproducibilidad.md`](docs/reproducibilidad.md).

### Notebooks

Se ejecutan en Google Colab o Kaggle con GPU. Requieren el conjunto de datos publicado en Hugging Face; el notebook `01` lo descarga. El orden importa: el segmentador debe entrenarse antes que los clasificadores.

## Convenciones de código

La regla transversal es que **el código no lleva comentarios**. Si un bloque necesita explicación, el problema es el nombre de la función o su tamaño. La justificación metodológica va en celdas markdown de los notebooks o en `docs/`.

### Dart

- Guía de estilo oficial de Dart; `dart format` con la configuración por defecto.
- Arquitectura limpia: `domain` no depende de nada, `infrastructure` implementa sus interfaces.
- Identificadores en inglés; español únicamente en cadenas visibles para la persona usuaria.
- `flutter analyze` debe pasar sin errores ni advertencias.

### Python

- PEP 8 con línea de 120 caracteres, aplicado por Ruff (`pyproject.toml`).
- Anotaciones de tipo en funciones públicas, con sintaxis PEP 604 (`X | None`, no `Optional[X]`).
- Una responsabilidad por función.

### Notebooks

- Cada celda de código va precedida de una celda markdown que explica qué hace y por qué.
- Sin comentarios dentro del código, conforme a la regla general.
- Limpia las salidas antes de confirmar, salvo que la salida sea el resultado que se quiere dejar registrado.
- Los notebooks caros (entrenamiento, ablación) deben poder reanudarse: guarda resultados parciales y omite las combinaciones ya calculadas.

## Verificación local

Reproduce lo que hará la integración continua:

```bash
flutter analyze
```

```bash
ruff check backend scripts && ruff format --check backend scripts
```

```bash
python scripts/validar_notebooks.py
```

## Flujo de trabajo

1. Haz un fork y crea una rama descriptiva: `feature/severidad-adaptativa`, `fix/mascara-fondo-suelo`.
2. Confirma con [Conventional Commits](https://www.conventionalcommits.org/es/): `feat:`, `fix:`, `docs:`, `refactor:`, `test:`, `chore:`.
3. Un pull request por cambio. No mezcles funcionalidades sin relación.
4. Rellena la plantilla de pull request y menciona `Closes #N` si cierra una incidencia.

## Cambios que exigen cuidado adicional

**Métricas del artículo.** Cualquier cambio que altere una cifra publicada obliga a actualizar [`docs/trazabilidad.md`](docs/trazabilidad.md) y a regenerar el archivo de evidencia correspondiente. No se aceptan números sin notebook que los produzca.

**Recomendaciones fitosanitarias.** Los cambios en `app/assets/data/tratamientos.json` afectan a decisiones de aplicación de productos en campo. Deben venir acompañados de la fuente agronómica que los respalda y respetar la normativa local.

**Umbrales de inferencia.** Los valores de `backend/inference/leaf_analyzer.py` y `backend/config.py` están calibrados sobre el corpus de entrenamiento. Modificarlos sin reevaluar invalida las métricas publicadas.

## Qué se agradece especialmente

- Correcciones de errores, con descripción del comportamiento esperado frente al observado.
- Validación con imágenes de campo propias, sobre todo de Santa Cruz: es la limitación más relevante del sistema.
- Partición por procedencia del conjunto de datos, que hoy no existe.
- Mejoras de rendimiento con medición antes y después.
- Traducciones de la interfaz.
