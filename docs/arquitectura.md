# Arquitectura

Descripción del sistema y de las decisiones de diseño que lo sostienen, con su justificación y su coste.

## Visión general

<div align="center">
  <img src="assets/pipeline.jpg" alt="Diagrama de actividad del sistema" width="720" />
</div>

Tres componentes ejecutables comparten una misma definición de la inferencia:

| Componente | Tecnología | Rol |
|---|---|---|
| `app/` | Flutter, TensorFlow Lite | Producto final. Inferencia local, sin conexión |
| `backend/` | FastAPI, TensorFlow Lite | Implementación de referencia y API opcional |
| `training/` | Keras, Colab o Kaggle | Entrenamiento, evaluación y exportación |

`backend/inference/` es la **fuente de verdad** del preprocesamiento, los umbrales y el encadenamiento. La aplicación replica ese comportamiento en Dart y los notebooks lo replican en las celdas de evaluación. Cuando algo cambia ahí, debe cambiar en los tres.

## La cascada

```
imagen ─> Shades-of-Gray ─> M_seg ─> hoja aislada ─> M1 ─┬─ sana ──> fin
                                                          │
                                                          └─ enferma ─> M2 ─> severidad CIELab
```

| Etapa | Modelo | Entrada | Salida | Archivo |
|---|---|---|---|---|
| Normalización | Shades-of-Gray, p = 6 | RGB | RGB corregido | `preprocessor.py` |
| Segmentación | U-Net ResNet50 | 256 × 256 | Máscara binaria | `segmenter.py` |
| Estado sanitario | EfficientNetB1 | 240 × 240 × 2 | Sigmoide | `classifier.py` |
| Patógeno | EfficientNetB0 | 224 × 224 × 2 | Softmax de 5 | `classifier.py` |
| Severidad | Reglas CIELab | Región segmentada | Porcentaje y componentes | `leaf_analyzer.py` |

El encadenamiento lo orquesta `diagnosis.py`.

## Decisiones de diseño

### Por qué doble entrada

Los clasificadores reciben dos tensores: la imagen normalizada y esa misma imagen con el fondo puesto a cero según la máscara del segmentador. Ambas ramas pasan por **el mismo codificador** (una sola instancia de EfficientNet, con pesos compartidos) y sus vectores se concatenan antes de la cabeza de clasificación.

El estudio de ablación al presupuesto completo, con tres semillas, mide qué aporta cada pieza:

| Configuración | F1 macro | Δ |
|---|---|---|
| Completa | 0.969 ± 0.005 | — |
| Sin doble entrada | 0.965 ± 0.006 | −0.004 |
| Sin hoja aislada, segunda entrada cruda | 0.958 ± 0.003 | −0.011 |
| Sin Shades-of-Gray | 0.973 ± 0.007 | +0.004 |
| Sin promediado de pesos | 0.973 ± 0.005 | +0.004 |

La lectura importante está en la tercera fila: alimentar la segunda rama con la imagen cruda rinde **peor** que no tener segunda rama. El beneficio no viene de duplicar la capacidad, sino de la información complementaria que aporta el fondo eliminado. Es el único componente cuyo efecto supera la variabilidad entre semillas.

Shades-of-Gray y el promediado exponencial de pesos no mejoran la exactitud en este test. En el primer caso es coherente con su propósito: aporta robustez ante iluminación variable, que este conjunto no mide.

### Por qué la severidad no es una red

El porcentaje de área afectada se calcula con umbrales sobre L\*, a\* y b\* dentro de la región segmentada, separando clorosis, necrosis y pérdida de tejido foliar. Se eligió así por tres razones:

1. **Auditabilidad.** Cada píxel clasificado como sintomático puede señalarse en la superposición que ve la persona usuaria. Una regresión no ofrece eso.
2. **Datos.** Anotar severidad píxel a píxel para entrenar una red exigiría un esfuerzo de etiquetado que el proyecto no tenía.
3. **Coste.** No añade parámetros ni latencia.

El precio es que **los umbrales son fijos**: están calibrados sobre las condiciones de captura del corpus y requieren reajuste manual ante cámaras o iluminaciones muy distintas. Es la limitación más concreta del módulo.

### Por qué la cuantización es mixta

| Modelo | Keras | TFLite float32 | TFLite int8 |
|---|---|---|---|
| M1 (F1) | 0.980 | 0.980 | 0.975 (−0.005) |
| M2 (F1) | 0.968 | 0.968 | 0.928 (−0.040) |

La conversión a float32 es exacta: verifica que la exportación no introduce error. La cuantización entera, en cambio, tiene un coste desigual. En M1 es despreciable; en M2 cuesta cuatro puntos de F1, demasiado para la etapa que decide qué categoría de afección se reporta. El segmentador se evalúa en las mismas tres variantes sobre el 25 % reservado de las máscaras COCO, porque es la variante int8 la que se despliega.

Las salidas enteras se convierten a probabilidad con los parámetros reales del tensor, `(q − zero_point) × scale`, no con una división fija. En los modelos exportados aquí `scale = 1/256`, de modo que dividir entre 255 introducía un sesgo sistemático del 0.39 %. No alteraba ninguna decisión —tanto el `argmax` del segmentador y de M2 como el umbral de M1 son invariantes a un reescalado monótono— pero sí las confianzas mostradas al usuario. `scripts/verificar_paridad.py` comprueba la equivalencia contra el intérprete de referencia.

Por eso la configuración desplegada usa **segmentador e M1 en int8 y M2 en float32**. Es una decisión guiada por la medición, no por la preferencia de empaquetar todo igual.

Durante el desarrollo, una versión anterior de M1 en int8 colapsaba a predecir siempre la misma clase (exactitud 0.500). La causa era que el conjunto representativo de calibración tomaba las primeras N imágenes de una lista ordenada por clase, de modo que **todas pertenecían a la misma**. Un conjunto representativo desbalanceado no degrada el modelo de forma gradual: lo rompe. La corrección está en `_cls_samples()` del notebook `06`.

### Por qué el clima no toca el diagnóstico

El servicio climático consulta temperatura, humedad, precipitación y punto de rocío, y con reglas específicas por categoría desplaza el **nivel de severidad** un escalón y adelanta o retrasa la ventana estimada de aparición. No modifica en ningún caso qué categoría se identificó.

La separación es deliberada: el diagnóstico debe poder auditarse contra la imagen, y mezclar en él una señal externa lo haría irreproducible.

## Arquitectura de la aplicación

`app/lib/` sigue una arquitectura limpia en cuatro capas, con la dependencia siempre hacia el dominio:

| Capa | Contiene | Depende de |
|---|---|---|
| `domain/` | Entidades y contratos | Nada |
| `application/` | Casos de uso | `domain` |
| `infrastructure/` | TFLite, Open-Meteo, base de tratamientos | `domain` |
| `presentation/` | Pantallas y widgets | `application`, `domain` |

Esta disposición permite sustituir la fuente climática o el motor de inferencia sin tocar la lógica de diagnóstico.

## Limitaciones estructurales

Estas no son defectos por corregir en una versión menor: son propiedades del diseño actual.

- **Sin partición por procedencia.** Las métricas reflejan desempeño interno del corpus, no generalización a dominios nuevos.
- **Umbrales CIELab fijos**, con la recalibración manual que eso implica.
- **Modelos empaquetados, sin actualización remota.** Es una decisión de seguridad, pero obliga a publicar una versión de la app para corregir un modelo.
- **Cinco categorías de afección.** Una enfermedad fuera de esas clases se asignará a la más parecida, con confianza posiblemente alta.
