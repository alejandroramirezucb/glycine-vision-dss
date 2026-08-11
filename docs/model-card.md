---
license: unknown
pipeline_tag: image-classification
tags:
- agriculture
- plant-disease
- soybean
- computer-vision
- tensorflow-lite
- edge-ai
language:
- es
base_model:
- google/efficientnet-b0
- google/efficientnet-b1
---

# Glycine Vision: modelos de triaje fitosanitario en soya

Modelos del sistema **Glycine Vision**, un asistente móvil de apoyo al triaje fitosanitario en soya (*Glycine max*) que segmenta la hoja, determina su estado sanitario, asigna la categoría de afección y estima la severidad foliar con inferencia local, sin conexión.

Entrenados sobre [`soybean_image_dataset`](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset). Código y notebooks de reproducción en [glycine-vision-dss](https://github.com/alejandroramirezucb/glycine-vision-dss).

> **Herramienta de apoyo al triaje**, no un sustituto del criterio agronómico ni del diagnóstico de laboratorio. Véanse [Limitaciones](#limitaciones).

## Arquitectura

```
imagen ─> Shades-of-Gray ─> M_seg ─> hoja aislada ─> M1 ─┬─ sana ──> fin
                                                          │
                                                          └─ enferma ─> M2 ─> severidad CIELab
```

| Modelo | Arquitectura | Entrada | Salida |
|---|---|---|---|
| **M_seg** | U-Net con codificador ResNet50 | 256 × 256 | Máscara hoja–fondo |
| **M1** | EfficientNetB1, doble entrada | 240 × 240 | Sana o enferma |
| **M2** | EfficientNetB0, doble entrada | 224 × 224 | Cinco categorías de afección foliar |

M1 y M2 reciben **dos entradas**: la imagen normalizada y la hoja aislada mediante la máscara de M_seg. Ambas ramas comparten codificador y sus vectores se concatenan antes de la cabeza de clasificación.

La severidad no la produce una red: se calcula con reglas de color en CIELab dentro de la región segmentada, lo que la hace auditable píxel a píxel.

## Archivos

| Archivo | Variante | Tamaño |
|---|---|---|
| `model_seg.keras` | Keras | 491 MB |
| `model_seg.tflite` · `model_seg_int8.tflite` | TFLite float32 · int8 | 167 MB · 42 MB |
| `model1_binary.keras` | Keras | 60 MB |
| `model1.tflite` · `model1_int8.tflite` | TFLite float32 · int8 | 27 MB · 9 MB |
| `model2_pathogen.keras` | Keras | 48 MB |
| `model2.tflite` · `model2_int8.tflite` | TFLite float32 · int8 | 18 MB · 6 MB |
| `labels_m1.txt` · `labels_m2.txt` | Orden de clases | — |
| `model_metadata.json` | Contrato de entradas y salidas | — |

## Desempeño

Sobre el conjunto de prueba independiente:

| Modelo | Métrica | Valor | IC 95 % |
|---|---|---|---|
| M_seg | Recall de hoja (Dice; IoU) | 0.974 (0.885; 0.808) | — |
| M1 | Exactitud (recall clase enferma) | 0.980 (1.000) | 0.960–0.995 |
| M2 | Exactitud / F1 macro | 0.969 / 0.968 | 0.949–0.986 |

**Calibración.** Ambos clasificadores están bien calibrados (ECE < 0.05). M1 es ligeramente sobreconfiado (0.986 frente a 0.980 de exactitud) y M2 subconfiado (0.935 frente a 0.969), un sesgo conservador deseable en triaje.

**Costo en dispositivo.** En un Xiaomi 2203129G de gama media, con variantes int8, cuatro hilos y `benchmark_model` de TensorFlow Lite: 126 ms (M_seg), 19 ms (M1) y 12 ms (M2). El flujo completo suma unos 157 ms por hoja.

### Efecto de la cuantización

| Modelo | Keras | TFLite float32 | TFLite int8 |
|---|---|---|---|
| M1 (F1) | 0.980 | 0.980 | 0.975 (−0.005) |
| M2 (F1) | 0.968 | 0.968 | 0.928 (−0.040) |

La conversión a float32 es exacta. La cuantización entera es prácticamente gratuita en M1 y costosa en M2, así que la **configuración desplegada** usa M_seg e M1 en int8 y **M2 en float32**.

## Preprocesamiento

Reproducirlo con exactitud es indispensable: las métricas anteriores no se sostienen con otro preprocesamiento.

1. **Shades-of-Gray** sobre la imagen RGB: norma de Minkowski *p* = 6, con la ganancia acotada a [0.6, 1.6].
2. **M_seg** sobre la imagen normalizada a 256 × 256, dividida entre 255. Se conserva el mayor componente conexo.
3. **Hoja aislada**: la imagen normalizada con el fondo puesto a cero según la máscara.
4. M1 y M2 reciben la imagen normalizada y la hoja aislada **en el rango [0, 255]**. Las redes EfficientNet incluyen su propia capa de reescalado: no debe aplicarse ninguna normalización adicional.

La implementación de referencia está en `backend/inference/` del repositorio.

## Uso previsto

Apoyo al triaje fitosanitario en campo: orientar al productor sobre qué hoja merece atención y con qué urgencia. Las recomendaciones de tratamiento que deriva el sistema son orientativas y deben verificarse contra la etiqueta del producto y la normativa local antes de cualquier aplicación.

## Limitaciones

- Entrenados con un corpus que combina ocho fuentes públicas **sin partición por procedencia**: las métricas reflejan desempeño interno del corpus, no evidencia de generalización a dominios nuevos.
- **Sin validación con imágenes propias de Santa Cruz** (Bolivia). La aplicabilidad regional es plausible pero no demostrada.
- La verdad de campo de la categoría de afección proviene de las etiquetas del conjunto de datos, no de diagnóstico de laboratorio. Las cinco clases son categorías operativas, no una taxonomía patogénica: la roya es un hongo pero se mantiene separada de las demás fúngicas, y plagas/insectos corresponde a daño por artrópodos, no a un patógeno.
- Los umbrales CIELab de severidad son fijos y requieren recalibración ante condiciones de captura distintas.
- El desempeño puede degradarse bajo iluminación extrema u oclusión foliar severa.
- **Cinco categorías cerradas.** Una enfermedad fuera de ellas se asignará a la más parecida, posiblemente con confianza alta.

## Licencia

Los modelos derivan de un conjunto de datos con licencias mixtas, que incluye una fuente **CC BY-NC-SA 4.0** y dos sin licencia declarada. En consecuencia se distribuyen para **investigación académica, sin uso comercial**; véase la [tarjeta del conjunto de datos](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset). El código del proyecto se publica bajo MIT.

## Cita

> Jaldín Torrico, E., & Ramírez Vallejos, A. (2026b). *Glycine Vision: modelos de triaje fitosanitario en soya* [Modelo]. Hugging Face. https://huggingface.co/alejandroramirezucb/glycine-vision-models
