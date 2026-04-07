# Glycine Vision Dsion Support System

## Alcance

Sistema de soporte de decision para diagnostico visual de soya usando dos modelos Keras secuenciales.

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
- La informacion de tratamiento (quimico, cultural, biologico y preventivo) se carga desde `Code/tratamientos.json`.

Ejemplo de decision:

- Si `fungal_diseases = 0.62` es la probabilidad mas alta, se selecciona la categoria **Fungicas** y se despliega su tratamiento asociado.

## Prerrequisitos

- Python 3.10+
- Dependencias en `Code/requirements.txt`
- Modelos en `Models/glycine-vision-hs` y `Models/glycine-vision-pd`

## Preparacion del entorno

```bash
python -m pip install -r Code/requirements.txt
```

### Scripts

```bash
# Analisis preliminar del dataset
python Code/scripts/analyze.py

# Pipeline completo (filtro + muestreo + exportacion)
python Code/scripts/pipeline.py

# Generacion del dataset de prueba
python Code/scripts/generate_test_set.py
```

### Aplicacion

```bash
python Code/src/main.py
```

## Procedimiento de uso

1. Cargar imagen o abrir camara.
2. Ejecutar clasificacion de salud.
3. Si el resultado es `diseased`, ejecutar clasificacion de enfermedad.
4. Revisar probabilidades de mayor a menor.
