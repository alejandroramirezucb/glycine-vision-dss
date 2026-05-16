# Glycine Vision Decision Support System

## Alcance

Sistema de soporte de decision para diagnostico visual de soya usando dos modelos Keras secuenciales.

### Dataset

Hugging Face: [Ver dataset](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset)

### Articulo Cientifico

Documento: [Ver documento](./Articulo%20Cientifico.pdf)

### Diapositivas

Diapositivas: [Ver diapositivas](https://gamma.app/docs/Glycine-Vision-Sistema-de-Triaje-Fitosanitario-Digital-para-Detec-ir5ilg0bcpnenm9)

### Modelo 1: Health Classification (glycine-vision-hs)

Clasificacion binaria de estado general de la hoja:

- `healthy`: Sin signos visibles de enfermedades
- `diseased`: Presencia de enfermedad

### Modelo 2: Disease Classification (glycine-vision-pd)

Clasificacion de tipo de enfermedad (solo si Modelo 1 retorna `diseased`):

- `bacterial_diseases`: Enfermedades bacterianas
- `fungal_diseases`: Enfermedades fungicas
- `rust_disease`: Roya
- `insect_pests`: Daño por plagas de insectos
- `viral_diseases`: Enfermedades virales

## Regla de decision y tratamiento

- El modelo 2 devuelve un vector de probabilidades para las 5 clases.
- El sistema ordena las clases por porcentaje y toma la de mayor valor (`top_prediction`).
- El tratamiento mostrado en la interfaz se obtiene segun esa clase dominante.
- La informacion de tratamiento (quimico, cultural, biologico y preventivo) se carga desde `Code/assets/data/tratamientos.json`.

## Prerrequisitos

- Flutter SDK 3.x
- Python 3.10+ (solo para web — servidor de inferencia)
  - TensorFlow 2.20.0+
- Java 17+ (para build Android)
- Windows: **Developer Mode activado** (requerido por plugins nativos como `tflite_flutter`)
  → `start ms-settings:developers`
- Modelos TFLite en `Models/glycine-vision-hs/model.tflite` y `Models/glycine-vision-pd/model_unquant.tflite`

## Estructura del proyecto

```
App/
  lib/
    domain/        ← Entities, Treatment, Protocols
    application/   ← HealthCase, DiseaseCase
    infrastructure/← Classifier, TreatmentRepo
    presentation/  ← screens, widgets, state, Theme
  android/
  assets/
Models/
Scripts/
```

## Preparacion de modelos

Coloca los `.tflite` en `Models/glycine-vision-hs/model.tflite` y `Models/glycine-vision-pd/model_unquant.tflite`, luego copia a assets:

```bash
python Scripts/convert_models.py
```

## Ejecucion

### Web

Terminal 1:

```bash
cd Scripts

py -3.12 -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt


cd ..
Scripts\.venv\Scripts\python.exe Scripts\inference_server.py
```

Terminal 2:

```bash
cd App
flutter pub get
flutter run -d chrome
```

### Android

```bash
# ver servicios
flutter devices

# correr la app
cd App
flutter pub get
flutter run -d <device ID>

# instalar sin cable
flutter build apk --release && flutter install
adb install build/app/outputs/flutter-apk/app-release.apk
```

Requiere Java 17 (`set JAVA_HOME=C:\java17`).

### iOS (Mac)

```bash
cd App && flutter build ipa --release
```

Requerimientos: Xcode 15+, CocoaPods.

### Notebooks

Antes de cada notebook hay que colocar:

```bash
from google.colab import drive
drive.mount('/content/drive')

%cd "/content/drive/MyDrive/glycine_vision/Training/notebooks"
```
