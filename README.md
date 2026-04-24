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

## Scripts

- `Code/scripts/config.py`
  - Define rutas base de dataset, modelos y resultados.
  - Configura clases, limites de muestreo y parametros globales.
  - Valida que existan rutas antes de ejecutar el flujo.

- `Code/scripts/prepare_dataset.py`
  - Carga imagenes desde `D:\Datasets\Dataset`.
  - Valida calidad minima (resolucion y canales RGB).
  - Elimina duplicados por hash MD5.
  - Crea y copia subconjuntos para `clasificacion_binaria` y `clasificacion_patogeno`.

  ```bash
  python Code/scripts/prepare_dataset.py
  ```

- `Code/scripts/evaluate_models.py`
  - Evalua los modelos con el set de test.
  - Calcula accuracy, precision, recall y F1 por clase.
  - Exporta resultados a Excel en `D:\Results`.

  ```bash
  python Code/scripts/evaluate_models.py
  ```

- `Code/scripts/pipeline.py`
  - Valida configuracion.
  - Ejecuta preparacion de dataset.
  - Ejecuta evaluacion de modelos.

  ```bash
  python Code/scripts/pipeline.py
  ```

### Ejecutar

```bash
python Code/src/main.py
```

## Docker (acceso web desde navegador o Android)

### Construir la imagen

```powershell
docker build -t glycine-vision .
```

### Levantar el contenedor

```powershell
docker run -d --rm -p 8550:8550 --name glycine glycine-vision
```

Luego abrir en el navegador: `http://localhost:8550`

Desde el celular (misma red): `http://<IP-de-tu-PC>:8550`

Para obtener la IP de tu PC:

```powershell
(Get-NetIPAddress -AddressFamily IPv4 -InterfaceAlias "Wi-Fi").IPAddress
```

### Detener el contenedor

```powershell
docker stop glycine
```

### Reconstruir y relevantar

```powershell
docker stop glycine 2>$null; docker build -t glycine-vision . && docker run -d --rm -p 8550:8550 --name glycine glycine-vision
```

### Ver logs del contenedor

```powershell
docker logs -f glycine
```

---

## Procedimiento de uso

1. Cargar imagen o abrir camara.
2. Ejecutar clasificacion de salud.
3. Si el resultado es `diseased`, ejecutar clasificacion de enfermedad.
4. Revisar probabilidades de mayor a menor.
