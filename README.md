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

- Python 3.10+ (para servidor de inferencia web)
- Flutter SDK 3.x
- Java 17+ (para build Android)
- Dependencias Flutter: `Code/pubspec.yaml`
- Modelos en `Models/glycine-vision-hs` y `Models/glycine-vision-pd`

## Estructura del proyecto

```
Code/
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

Descarga modelos de Teachable Machine (.h5) a `Models/glycine-vision-hs` y `Models/glycine-vision-pd`, luego:

```bash
python Scripts/convert_models.py
```

## Ejecucion

### Web

```bash
cd Code && flutter pub get
flutter run -d chrome
```

### Windows

```bash
cd Code
flutter pub get
flutter run -d windows
```

### Android APK

```bash
set JAVA_HOME=C:\java17
cd Code
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
adb install build/app/outputs/flutter-apk/app-release.apk
```

Requiere Java 17.

### iOS (Mac)

```bash
cd Code && flutter build ipa --release
# → build/ios/ipa/
```

Requerimientos: Xcode 15+, CocoaPods.
