<div align="center">
  <img src="Images/logo.png" alt="Glycine Vision DSS" width="180" />
  <br /><br />

  <h1>Glycine Vision DSS</h1>
  <p><strong>Sistema de Soporte a Decisiones para el diagnóstico de enfermedades en soya</strong></p>

  <p>
    <img src="https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter" alt="Flutter" />
    <img src="https://img.shields.io/badge/Python-3.10+-3776AB?logo=python" alt="Python" />
    <img src="https://img.shields.io/badge/TFLite-2.x-FF6F00?logo=tensorflow" alt="TFLite" />
    <img src="https://img.shields.io/badge/Plataforma-Android%20%7C%20iOS%20%7C%20Web-lightgrey" alt="Platform" />
    <img src="https://img.shields.io/badge/Licencia-MIT-green" alt="License" />
  </p>
</div>

---

## ¿Qué es?

Glycine Vision DSS es una aplicación móvil y web que detecta enfermedades foliares en cultivos de soya (*Glycine max*) usando visión por computadora. Dos modelos EfficientNet cuantizados corren **directamente en el dispositivo** — sin enviar imágenes a ningún servidor.

El sistema identifica patógenos, estima severidad por zona, recomienda tratamientos y, cuando hay conexión, incorpora datos climáticos en tiempo real para estimar el riesgo epidemiológico.

---

## Características principales

| | Capacidad |
|---|---|
| 🔍 | **Detección local** — inferencia TFLite sin internet requerido |
| 🦠 | **5 clases de patógenos** — bacterianas, fúngicas, roya, virales, plagas/insectos |
| 📊 | **Severidad por zona** — porcentaje de tejido afectado por región de la hoja |
| 💊 | **Recomendaciones de tratamiento** — protocolos biológicos, químicos y culturales |
| 🌤️ | **Riesgo climático** — integración con Open-Meteo para alertas epidemiológicas |
| ⏱️ | **Estimación de onset** — proyección de días a aparición de síntomas |
| 📱 | **Multi-plataforma** — Android, iOS y Web desde un único código base |

---

## Arquitectura

```
┌─────────────────────────────────────────────────────┐
│                   Flutter App                       │
│                                                     │
│  HomeScreen ──► DiagnoseUseCase ──► LocalDiagnoser  │
│                                         │           │
│                                    ┌────┴────┐      │
│                                    │ TFLite  │      │
│                                    │ M1 (HS) │      │  M1: Salud binaria (EfficientNetB1 240×240)
│                                    │ M2 (PD) │      │  M2: Patógeno multi-label (EfficientNetB0 224×224)
│                                    └─────────┘      │
│                                         │           │
│                              SeverityCalculator     │
│                              TreatmentRepo          │
│                              OnsetEstimator         │
│                              OpenMeteoClient        │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│              Python Inference Server (opcional)      │
│                                                     │
│  FastAPI ──► inference_server.py ──► TFLite models  │
│  POST /api/diagnose                                 │
└─────────────────────────────────────────────────────┘
```

### Pipeline de diagnóstico

```
Imagen
  │
  ▼
Resize (≤400px) ──► Sliding window 150px / stride 100px
  │
  ├── Filtro de hoja (ratio verde/amarillo ≥ 12%)
  │       └── Patches sin hoja descartados
  │
  ├── M1: ¿Patch enfermo? (umbral 0.35)
  │       └── Patches sanos descartados
  │
  ├── M2: ¿Qué patógeno? (multi-label, umbrales calibrados)
  │
  ├── HSV Severity: % de tejido afectado por patch
  │
  └── Agregación → Findings → Tratamientos → Resultado
```

---

## Inicio rápido

### Prerequisitos

- Flutter SDK ≥ 3.0
- Python ≥ 3.10 (solo para servidor)
- Modelos entrenados (ver sección de entrenamiento)

### App móvil / web

```bash
cd App
flutter pub get

# Android / iOS
flutter run --release

# Web
flutter run -d chrome
```

### Servidor Python (para diagnóstico vía HTTP)

```bash
cd Scripts
pip install fastapi uvicorn opencv-python tensorflow numpy requests
python inference_server.py
# Servidor en http://localhost:8001
```

### Entrenamiento de modelos

Los notebooks en `Training/notebooks/` cubren el pipeline completo:

| Notebook | Descripción |
|---|---|
| `01_dataset_prep.ipynb` | Preparación y splits del dataset |
| `02_train_model1_binary.ipynb` | Entrenamiento M1 — clasificación binaria sana/enferma |
| `03_train_model2_pathogen.ipynb` | Entrenamiento M2 — clasificación multi-label de patógenos |
| `04_evaluate.ipynb` | Evaluación, curvas ROC, matrices de confusión |
| `05_export_tflite.ipynb` | Exportación a TFLite float32 e int8 |

Ejecutar en Google Colab con GPU T4.

---

## Estructura del proyecto

```
glycine-vision-dss/
├── App/                          # Flutter app
│   ├── lib/
│   │   ├── domain/               # Entidades y contratos
│   │   ├── infrastructure/       # TFLite, HTTP, calculadoras
│   │   ├── application/          # Casos de uso
│   │   └── presentation/         # Pantallas, widgets, estado
│   └── assets/models/            # Modelos TFLite + labels
│       ├── hs/                   # Health/Binary model
│       └── pd/                   # Pathogen/Disease model
├── Scripts/
│   └── inference_server.py       # FastAPI server
├── Training/
│   ├── notebooks/                # Jupyter notebooks de entrenamiento
│   ├── src/                      # Módulos de inferencia Python
│   └── outputs/                  # Modelos entrenados (.keras, .tflite)
├── Models/                       # Modelos para el servidor
│   ├── glycine-vision-hs/
│   └── glycine-vision-pd/
└── Images/                       # Assets del proyecto
```

---

## Modelos

| Modelo | Backbone | Input | Tarea | Accuracy |
|---|---|---|---|---|
| M1 (Health Screen) | EfficientNetB1 | 240×240 | Binaria: sana / enferma | ~0.98 |
| M2 (Pathogen ID) | EfficientNetB0 | 224×224 | Multi-label: 5 clases | mAP ~0.97 |

**Clases M2:** `bacterianas` · `fungicas` · `roya` · `virales` · `plagas_insectos`

Los modelos TFLite se cuantizan a int8 dinámico para reducir tamaño (~5-8 MB) y acelerar inferencia.

---

## Roadmap

- [ ] Alertas predictivas de riesgo por clima (antes de síntomas visibles)
- [ ] Historial de diagnósticos con geolocalización (mapa de campo)
- [ ] Seguimiento de tratamientos y retroalimentación de eficacia
- [ ] Recomendaciones IPM en 3 niveles (biológico / bajo-químico / químico)
- [ ] Calendario estacional de riesgo epidemiológico offline
- [ ] Soporte multilenguaje

---

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para guías de desarrollo, convenciones de código y proceso de pull requests.

## Código de conducta

Ver [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).

## Seguridad

Ver [SECURITY.md](SECURITY.md) para reportar vulnerabilidades.

---

## Licencia

MIT © 2026 — Ver [LICENSE](LICENSE) para detalles.

---

<div align="center">
  <sub>Construido con Flutter · TensorFlow Lite · FastAPI</sub>
</div>
