"""Generator for the six training notebooks. Run once from this folder."""
import json
from pathlib import Path


def make_nb(cells):
    return {
        "cells": cells,
        "metadata": {
            "kernelspec": {"display_name": "Python 3", "language": "python", "name": "python3"},
            "language_info": {"name": "python", "version": "3.10"},
            "accelerator": "GPU",
            "colab": {"provenance": []},
        },
        "nbformat": 4,
        "nbformat_minor": 5,
    }


def md(text):
    return {"cell_type": "markdown", "metadata": {}, "source": text.splitlines(keepends=True)}


def code(text):
    return {"cell_type": "code", "execution_count": None, "metadata": {}, "outputs": [],
            "source": text.splitlines(keepends=True)}


NB01 = make_nb([
    md("""# 01 - Preparacion del Dataset

Descarga el dataset desde HuggingFace, valida imagenes, deduplica por MD5 y crea splits train/val.

Dataset: [`alejandroramirezucb/soybean_image_dataset`](https://huggingface.co/datasets/alejandroramirezucb/soybean_image_dataset)
"""),
    code("""!pip install -q huggingface_hub Pillow tqdm scikit-learn"""),
    code("""import os
import hashlib
import shutil
import random
from pathlib import Path
from PIL import Image
from tqdm import tqdm
from huggingface_hub import snapshot_download

random.seed(42)

DATA_DIR = Path("./data")
DATA_DIR.mkdir(exist_ok=True)

snapshot_download(
    repo_id="alejandroramirezucb/soybean_image_dataset",
    repo_type="dataset",
    local_dir=str(DATA_DIR),
)
print("Descarga completada:", DATA_DIR)
"""),
    code("""def validar(p, min_size=100):
    try:
        img = Image.open(p)
        img.verify()
        img = Image.open(p)
        if img.mode != "RGB":
            return False
        w, h = img.size
        return w >= min_size and h >= min_size
    except Exception:
        return False


def md5(p):
    with open(p, "rb") as f:
        return hashlib.md5(f.read()).hexdigest()


def contar(base):
    base = Path(base)
    if not base.exists():
        print(f"  (no existe: {base})")
        return
    for clase in sorted(base.iterdir()):
        if clase.is_dir():
            n = sum(1 for _ in clase.rglob("*") if _.is_file())
            print(f"  {clase.name:25s}: {n:>5}")


print("Train binaria:")
contar(DATA_DIR / "Train" / "clasificacion_binaria")
print("Train patogeno:")
contar(DATA_DIR / "Train" / "clasificacion_patogeno")
print("Test binaria:")
contar(DATA_DIR / "Test" / "clasificacion_binaria")
print("Test patogeno:")
contar(DATA_DIR / "Test" / "clasificacion_patogeno")
"""),
    code("""CLEAN = Path("./clean")
CLEAN.mkdir(exist_ok=True)


def deduplicar_y_limpiar(origen: Path, destino: Path):
    destino.mkdir(parents=True, exist_ok=True)
    hashes = set()
    archivos = [p for p in origen.rglob("*") if p.suffix.lower() in {".jpg", ".jpeg", ".png", ".bmp"}]
    random.shuffle(archivos)
    keep = 0
    for p in tqdm(archivos, desc=str(origen.name)):
        if not validar(p):
            continue
        h = md5(p)
        if h in hashes:
            continue
        hashes.add(h)
        shutil.copy2(p, destino / f"{h[:8]}_{p.name}")
        keep += 1
    return keep


for split in ["Train", "Test"]:
    for tarea in ["clasificacion_binaria", "clasificacion_patogeno"]:
        src = DATA_DIR / split / tarea
        if not src.exists():
            continue
        for clase in src.iterdir():
            if clase.is_dir():
                dst = CLEAN / split / tarea / clase.name
                n = deduplicar_y_limpiar(clase, dst)
                print(f"{split}/{tarea}/{clase.name}: {n}")
"""),
    code("""from sklearn.model_selection import train_test_split

SPLIT = Path("./splits")
SPLIT.mkdir(exist_ok=True)


def hacer_split(tarea: str):
    base = CLEAN / "Train" / tarea
    out = SPLIT / tarea
    (out / "train").mkdir(parents=True, exist_ok=True)
    (out / "val").mkdir(parents=True, exist_ok=True)
    for clase in base.iterdir():
        if not clase.is_dir():
            continue
        archivos = list(clase.iterdir())
        if len(archivos) < 4:
            print(f"  ATENCION pocos archivos en {clase.name}")
            continue
        tr, va = train_test_split(archivos, test_size=0.2, random_state=42, shuffle=True)
        for split_name, lst in [("train", tr), ("val", va)]:
            dst = out / split_name / clase.name
            dst.mkdir(parents=True, exist_ok=True)
            for f in lst:
                shutil.copy2(f, dst / f.name)
        print(f"  {clase.name}: train={len(tr)} val={len(va)}")


print("Modelo 1 (binario):")
hacer_split("clasificacion_binaria")
print("\\nModelo 2 (patogeno):")
hacer_split("clasificacion_patogeno")
"""),
    code("""TEST_OUT = SPLIT / "test"
TEST_OUT.mkdir(exist_ok=True)
for tarea in ["clasificacion_binaria", "clasificacion_patogeno"]:
    src = CLEAN / "Test" / tarea
    if src.exists():
        dst = TEST_OUT / tarea
        if dst.exists():
            shutil.rmtree(dst)
        shutil.copytree(src, dst)
print("Test listo en", TEST_OUT)
"""),
    md("""## Verificar

- `splits/clasificacion_binaria/{train,val}/{soya_sana,soya_enferma}`
- `splits/clasificacion_patogeno/{train,val}/{bacterianas,fungicas,plagas_insectos,roya,virales}`
- `splits/test/clasificacion_{binaria,patogeno}/...`

Prosigue con `02_train_model1_binary.ipynb`.
"""),
])


ALBUMENTATIONS_SEQUENCE = '''
import albumentations as A
import numpy as np
import os
from pathlib import Path
from PIL import Image
from tensorflow.keras.utils import Sequence
from tensorflow.keras.applications.efficientnet import preprocess_input


TRAIN_AUG = A.Compose([
    A.Rotate(limit=45, border_mode=0, p=0.7),
    A.HorizontalFlip(p=0.5),
    A.VerticalFlip(p=0.3),
    # Simula variacion de iluminacion en campo
    A.RandomBrightnessContrast(brightness_limit=0.3, contrast_limit=0.3, p=0.6),
    A.HueSaturationValue(hue_shift_limit=15, sat_shift_limit=30, val_shift_limit=20, p=0.5),
    # Mejora deteccion de lesiones con bajo contraste
    A.CLAHE(clip_limit=3.0, tile_grid_size=(8, 8), p=0.4),
    # Ruido de camara y desenfoque por movimiento
    A.OneOf([
        A.GaussianBlur(blur_limit=(3, 5), p=1.0),
        A.MotionBlur(blur_limit=5, p=1.0),
    ], p=0.3),
    A.GaussNoise(var_limit=(5, 25), p=0.25),
    # Deformaciones geometricas suaves (simula perspectiva de hoja)
    A.OneOf([
        A.ElasticTransform(alpha=60, sigma=12, p=1.0),
        A.GridDistortion(num_steps=5, distort_limit=0.2, p=1.0),
        A.OpticalDistortion(distort_limit=0.15, p=1.0),
    ], p=0.3),
    A.ShiftScaleRotate(shift_limit=0.1, scale_limit=0.15, rotate_limit=0, p=0.4),
    A.CoarseDropout(max_holes=6, max_height=32, max_width=32, fill_value=0, p=0.2),
])

VAL_AUG = A.Compose([])  # Sin aumentacion en validacion


class LeafSequence(Sequence):
    """Generador compatible con Keras que usa albumentaciones."""

    def __init__(self, directory, img_size=(224, 224), batch_size=16,
                 augment=False, class_mode="binary", shuffle=True):
        self.img_size = img_size
        self.batch_size = batch_size
        self.augment = augment
        self.class_mode = class_mode
        self.shuffle = shuffle

        self.samples = []
        self.class_indices = {}
        classes = sorted(p.name for p in Path(directory).iterdir() if p.is_dir())
        for i, cls in enumerate(classes):
            self.class_indices[cls] = i
            for ext in ("*.jpg", "*.jpeg", "*.png", "*.bmp"):
                for fp in (Path(directory) / cls).glob(ext):
                    self.samples.append((str(fp), i))

        self.n = len(self.samples)
        self.classes = np.array([s[1] for s in self.samples])
        if shuffle:
            self._shuffle()

    def _shuffle(self):
        idx = np.random.permutation(len(self.samples))
        self.samples = [self.samples[i] for i in idx]
        self.classes = self.classes[idx]

    def __len__(self):
        return max(1, self.n // self.batch_size)

    def __getitem__(self, i):
        batch = self.samples[i * self.batch_size:(i + 1) * self.batch_size]
        imgs, labels = [], []
        for fp, label in batch:
            img = np.array(Image.open(fp).convert("RGB").resize(self.img_size))
            if self.augment:
                img = TRAIN_AUG(image=img)["image"]
            else:
                img = VAL_AUG(image=img)["image"]
            img = preprocess_input(img.astype(np.float32))
            imgs.append(img)
            labels.append(label)
        X = np.stack(imgs)
        if self.class_mode == "binary":
            Y = np.array(labels, dtype=np.float32)
        else:
            n_cls = len(self.class_indices)
            Y = np.eye(n_cls)[labels]
        return X, Y

    def on_epoch_end(self):
        if self.shuffle:
            self._shuffle()
'''


def common_train_cells(num_classes, class_mode, data_subdir, model_name,
                       epochs_phase1, epochs_phase2, lr_p1, lr_p2, use_class_weights=False):
    class_weights_cell = ""
    class_weights_fit_arg = ""
    if use_class_weights:
        class_weights_cell = """
from sklearn.utils.class_weight import compute_class_weight

all_labels = np.array([s[1] for s in train_gen.samples])
cw_values = compute_class_weight("balanced", classes=np.unique(all_labels), y=all_labels)
class_weights = dict(enumerate(cw_values))
print("Class weights:", class_weights)
"""
        class_weights_fit_arg = ", class_weight=class_weights"

    return [
        code("""!pip install -q tensorflow albumentations scikit-learn matplotlib"""),
        code(f"""import tensorflow as tf
import numpy as np
import json
from pathlib import Path
import matplotlib.pyplot as plt

# Sin mixed precision — simplifica export TFLite
tf.random.set_seed(42)
np.random.seed(42)
print("GPU:", tf.config.list_physical_devices("GPU"))

IMG_SIZE = (224, 224)
BATCH = 16
EPOCHS_P1 = {epochs_phase1}
EPOCHS_P2 = {epochs_phase2}
LR_P1 = {lr_p1}
LR_P2 = {lr_p2}

DATA = Path("./splits/{data_subdir}")
OUT = Path("./outputs")
OUT.mkdir(exist_ok=True)
"""),
        code(ALBUMENTATIONS_SEQUENCE + f"""
train_gen = LeafSequence(
    DATA / "train", img_size=IMG_SIZE, batch_size=BATCH,
    augment=True, class_mode="{class_mode}", shuffle=True,
)
val_gen = LeafSequence(
    DATA / "val", img_size=IMG_SIZE, batch_size=BATCH,
    augment=False, class_mode="{class_mode}", shuffle=False,
)
print(f"Train: {{train_gen.n}} imagenes | Val: {{val_gen.n}} imagenes")
print("Clases:", train_gen.class_indices)
with open(OUT / "class_indices_{model_name}.json", "w") as f:
    json.dump(train_gen.class_indices, f)
"""),
        code(f"""{class_weights_cell}
def construir(num_clases={num_classes}):
    base = tf.keras.applications.EfficientNetB0(
        weights="imagenet", include_top=False, input_shape=(*IMG_SIZE, 3)
    )
    base.trainable = False
    x = base.output
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(0.4)(x)
    x = tf.keras.layers.Dense(
        256, activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(1e-4)
    )(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    if num_clases == 1:
        out = tf.keras.layers.Dense(1, activation="sigmoid")(x)
    else:
        out = tf.keras.layers.Dense(num_clases, activation="softmax")(x)
    return tf.keras.Model(base.input, out, name="{model_name}")


model = construir()
loss = "binary_crossentropy" if {num_classes} == 1 else "categorical_crossentropy"
model.compile(
    optimizer=tf.keras.optimizers.Adam(LR_P1),
    loss=loss,
    metrics=[
        "accuracy",
        tf.keras.metrics.Precision(name="prec"),
        tf.keras.metrics.Recall(name="rec"),
    ],
)
model.summary()
"""),
        code(f"""cbs_p1 = [
    tf.keras.callbacks.EarlyStopping(
        monitor="val_accuracy", patience=6, restore_best_weights=True, verbose=1
    ),
    tf.keras.callbacks.ModelCheckpoint(
        filepath=str(OUT / "{model_name}_p1_best.keras"),
        monitor="val_accuracy", save_best_only=True, verbose=1,
    ),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss", factor=0.5, patience=3, min_lr=1e-7, verbose=1
    ),
]

print("=== FASE 1: cabeza (base congelada) ===")
h1 = model.fit(
    train_gen, validation_data=val_gen,
    epochs=EPOCHS_P1, callbacks=cbs_p1, verbose=1{class_weights_fit_arg},
)
"""),
        code(f"""# FASE 2: fine-tuning — descongelar ultimas 30 layers de EfficientNetB0
# EfficientNetB0 está aplanado directamente en model.layers (sin sub-modelo)
# Descongelar todos, luego congelar selectivamente
for layer in model.layers:
    layer.trainable = True

# Congelar todo excepto los ultimos 30 layers (bloques 5-6 + top)
for layer in model.layers[:-30]:
    layer.trainable = False

# BN congelado en fine-tuning evita inestabilidad
for layer in model.layers:
    if isinstance(layer, tf.keras.layers.BatchNormalization):
        layer.trainable = False

trainables = sum(1 for l in model.layers if l.trainable)
print(f"Layers entrenables: {{trainables}}")

model.compile(
    optimizer=tf.keras.optimizers.Adam(LR_P2),
    loss=loss,
    metrics=[
        "accuracy",
        tf.keras.metrics.Precision(name="prec"),
        tf.keras.metrics.Recall(name="rec"),
    ],
)

cbs_p2 = [
    tf.keras.callbacks.EarlyStopping(
        monitor="val_loss", patience=8, restore_best_weights=True, verbose=1
    ),
    tf.keras.callbacks.ModelCheckpoint(
        filepath=str(OUT / "{model_name}_p2_best.keras"),
        monitor="val_accuracy", save_best_only=True, verbose=1,
    ),
    tf.keras.callbacks.ReduceLROnPlateau(
        monitor="val_loss", factor=0.3, patience=4, min_lr=1e-8, verbose=1
    ),
]

print("=== FASE 2: fine-tuning (ultimos 30 layers) ===")
h2 = model.fit(
    train_gen, validation_data=val_gen,
    epochs=EPOCHS_P2, initial_epoch=len(h1.history["loss"]),
    callbacks=cbs_p2, verbose=1{class_weights_fit_arg},
)

model.save(OUT / "{model_name}.keras")
print("Modelo guardado en", OUT / "{model_name}.keras")
"""),
        code(f"""acc = h1.history["accuracy"] + h2.history["accuracy"]
vacc = h1.history["val_accuracy"] + h2.history["val_accuracy"]
loss_h = h1.history["loss"] + h2.history["loss"]
vloss = h1.history["val_loss"] + h2.history["val_loss"]

fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 4))
div = len(h1.history["accuracy"])
ep = range(1, len(acc) + 1)
for ax, t, v, ylabel in [(ax1, acc, vacc, "Accuracy"), (ax2, loss_h, vloss, "Loss")]:
    ax.plot(ep, t, "b-", label="train")
    ax.plot(ep, v, "r-", label="val")
    ax.axvline(div, color="gray", linestyle="--", label="inicio fine-tune")
    ax.set_xlabel("Epoca"); ax.set_ylabel(ylabel); ax.legend(); ax.grid(alpha=0.3)
plt.tight_layout()
plt.savefig(OUT / "{model_name}_curves.png", dpi=120)
plt.show()
"""),
    ]


NB02 = make_nb(
    [md("""# 02 - Entrenar Modelo 1 (binario: sana vs enferma)

Transfer learning con EfficientNetB0. Dos fases: cabeza + fine-tuning.
Augmentacion con albumentations (rotacion, color jitter, distorsion elastica).
Mixed precision float16 para mayor velocidad en T4.
""")] + common_train_cells(
        num_classes=1,
        class_mode="binary",
        data_subdir="clasificacion_binaria",
        model_name="model1_binary",
        epochs_phase1=15, epochs_phase2=25,
        lr_p1=1e-3, lr_p2=1e-5,
        use_class_weights=False,
    )
)


NB03 = make_nb(
    [md("""# 03 - Entrenar Modelo 2 (5 clases de patogeno)

Mismo pipeline que M1, con softmax para 5 clases.
Class weights balanceados para compensar desbalance entre clases.

Clases: `bacterianas`, `fungicas`, `plagas_insectos`, `roya`, `virales`.
""")] + common_train_cells(
        num_classes=5,
        class_mode="categorical",
        data_subdir="clasificacion_patogeno",
        model_name="model2_pathogen",
        epochs_phase1=20, epochs_phase2=35,
        lr_p1=1e-3, lr_p2=5e-6,
        use_class_weights=True,
    )
)


NB04 = make_nb([
    md("""# 04 - Evaluacion sobre Test

Carga ambos modelos entrenados y evalua sobre `splits/test/`. Genera matrices de confusion y reporta F1 por clase.
"""),
    code("""!pip install -q tensorflow scikit-learn matplotlib seaborn"""),
    code("""import tensorflow as tf
import numpy as np
import json
from pathlib import Path
from sklearn.metrics import (
    classification_report, confusion_matrix, ConfusionMatrixDisplay,
    accuracy_score, f1_score, precision_score, recall_score,
)
import matplotlib.pyplot as plt
import seaborn as sns

OUT = Path("./outputs")
SPLIT = Path("./splits")

m1 = tf.keras.models.load_model(OUT / "model1_binary.keras")
m2 = tf.keras.models.load_model(OUT / "model2_pathogen.keras")
print("Modelos cargados OK")
"""),
    code("""# Importar el generador de datos (mismo que en entrenamiento, sin augmentacion)
import sys
sys.path.insert(0, "..")

import albumentations as A
import numpy as np
from pathlib import Path
from PIL import Image
from tensorflow.keras.utils import Sequence
from tensorflow.keras.applications.efficientnet import preprocess_input

VAL_AUG = A.Compose([])

class LeafSequence(Sequence):
    def __init__(self, directory, img_size=(224, 224), batch_size=32, class_mode="binary"):
        self.img_size = img_size
        self.batch_size = batch_size
        self.class_mode = class_mode
        self.samples = []
        self.class_indices = {}
        classes = sorted(p.name for p in Path(directory).iterdir() if p.is_dir())
        for i, cls in enumerate(classes):
            self.class_indices[cls] = i
            for ext in ("*.jpg", "*.jpeg", "*.png", "*.bmp"):
                for fp in (Path(directory) / cls).glob(ext):
                    self.samples.append((str(fp), i))
        self.n = len(self.samples)
        self.classes = np.array([s[1] for s in self.samples])

    def __len__(self):
        return max(1, (self.n + self.batch_size - 1) // self.batch_size)

    def __getitem__(self, i):
        batch = self.samples[i * self.batch_size:(i + 1) * self.batch_size]
        imgs, labels = [], []
        for fp, label in batch:
            img = np.array(Image.open(fp).convert("RGB").resize(self.img_size))
            img = preprocess_input(img.astype(np.float32))
            imgs.append(img)
            labels.append(label)
        X = np.stack(imgs)
        if self.class_mode == "binary":
            Y = np.array(labels, dtype=np.float32)
        else:
            Y = np.eye(len(self.class_indices))[labels]
        return X, Y
"""),
    code("""test1 = LeafSequence(
    SPLIT / "test" / "clasificacion_binaria",
    batch_size=32, class_mode="binary",
)
preds1 = (m1.predict(test1, verbose=1) > 0.5).astype(int).flatten()
reales1 = test1.classes[:len(preds1)]
print("=== Modelo 1 ===")
print(classification_report(reales1, preds1, target_names=list(test1.class_indices.keys()), digits=4))

fig, ax = plt.subplots(figsize=(5, 4))
cm1 = confusion_matrix(reales1, preds1)
sns.heatmap(cm1, annot=True, fmt="d", cmap="Blues",
            xticklabels=list(test1.class_indices.keys()),
            yticklabels=list(test1.class_indices.keys()), ax=ax)
ax.set_title("Modelo 1 - Confusion")
plt.tight_layout()
plt.savefig(OUT / "cm_m1.png", dpi=120)
plt.show()
"""),
    code("""test2 = LeafSequence(
    SPLIT / "test" / "clasificacion_patogeno",
    batch_size=32, class_mode="categorical",
)
probs2 = m2.predict(test2, verbose=1)
preds2 = np.argmax(probs2, axis=1)
reales2 = test2.classes[:len(preds2)]
names2 = list(test2.class_indices.keys())
print("=== Modelo 2 ===")
print(classification_report(reales2, preds2, target_names=names2, digits=4))

fig, ax = plt.subplots(figsize=(8, 7))
cm2 = confusion_matrix(reales2, preds2)
sns.heatmap(cm2, annot=True, fmt="d", cmap="Blues",
            xticklabels=names2, yticklabels=names2, ax=ax)
ax.set_title("Modelo 2 - Confusion (5 clases)")
plt.xticks(rotation=30)
plt.tight_layout()
plt.savefig(OUT / "cm_m2.png", dpi=120)
plt.show()
"""),
    code("""metrics = {
    "m1": {
        "accuracy": float(accuracy_score(reales1, preds1)),
        "f1": float(f1_score(reales1, preds1, zero_division=0)),
        "precision": float(precision_score(reales1, preds1, zero_division=0)),
        "recall": float(recall_score(reales1, preds1, zero_division=0)),
    },
    "m2": {
        "accuracy": float(accuracy_score(reales2, preds2)),
        "f1_macro": float(f1_score(reales2, preds2, average="macro", zero_division=0)),
        "f1_per_class": {
            n: float(s) for n, s in zip(
                names2, f1_score(reales2, preds2, average=None, zero_division=0)
            )
        },
    },
}
with open(OUT / "training_metrics.json", "w") as f:
    json.dump(metrics, f, indent=2, ensure_ascii=False)
print(json.dumps(metrics, indent=2, ensure_ascii=False))

# Verificar objetivos
print("\\n=== Verificacion de objetivos ===")
print(f"M1 accuracy: {metrics['m1']['accuracy']:.4f}  (objetivo >= 0.85) {'OK' if metrics['m1']['accuracy'] >= 0.85 else 'FALLA'}")
print(f"M1 F1:       {metrics['m1']['f1']:.4f}  (objetivo >= 0.85) {'OK' if metrics['m1']['f1'] >= 0.85 else 'FALLA'}")
print(f"M2 accuracy: {metrics['m2']['accuracy']:.4f}  (objetivo >= 0.75) {'OK' if metrics['m2']['accuracy'] >= 0.75 else 'FALLA'}")
print(f"M2 macro F1: {metrics['m2']['f1_macro']:.4f}  (objetivo >= 0.70) {'OK' if metrics['m2']['f1_macro'] >= 0.70 else 'FALLA'}")
for cls, f1v in metrics['m2']['f1_per_class'].items():
    print(f"  {cls:20s}: F1={f1v:.4f}  {'OK' if f1v >= 0.65 else 'REVISAR'}")
"""),
])


NB05 = make_nb([
    md("""# 05 - Exportar a TFLite

Convierte ambos modelos a `.tflite` con cuantizacion int8 dinamica. Verifica tamaño y prueba inferencia.
"""),
    code("""!pip install -q tensorflow"""),
    code("""import tensorflow as tf
import numpy as np
from pathlib import Path

OUT = Path("./outputs")

# Cargar modelos originales (pueden estar en mixed_float16 si se entrenaron así)
tf.keras.mixed_precision.set_global_policy("float32")
m1_orig = tf.keras.models.load_model(OUT / "model1_binary.keras")
m2_orig = tf.keras.models.load_model(OUT / "model2_pathogen.keras")
print("Modelos originales cargados")
print("M1 layers:", len(m1_orig.layers))
print("M2 layers:", len(m2_orig.layers))
"""),
    code("""def reconstruir_float32(original, num_clases, model_name):
    '''
    Reconstruye el modelo en float32 puro copiando los pesos del original.
    Necesario cuando el modelo fue entrenado con mixed_float16: los pesos
    se guardan en float32 pero el grafo tiene operaciones float16 que TFLite
    no puede convertir. Reconstruir en float32 elimina esas operaciones.
    '''
    IMG = (224, 224)
    base = tf.keras.applications.EfficientNetB0(
        weights=None, include_top=False, input_shape=(*IMG, 3)
    )
    x = base.output
    x = tf.keras.layers.GlobalAveragePooling2D()(x)
    x = tf.keras.layers.BatchNormalization()(x)
    x = tf.keras.layers.Dropout(0.4)(x)
    x = tf.keras.layers.Dense(
        256, activation="relu",
        kernel_regularizer=tf.keras.regularizers.l2(1e-4)
    )(x)
    x = tf.keras.layers.Dropout(0.3)(x)
    if num_clases == 1:
        out = tf.keras.layers.Dense(1, activation="sigmoid")(x)
    else:
        out = tf.keras.layers.Dense(num_clases, activation="softmax")(x)
    nuevo = tf.keras.Model(base.input, out, name=model_name)

    # Los pesos del original ya son float32 aunque se computaran en float16
    nuevo.set_weights(original.get_weights())
    print(f"  {model_name}: {len(nuevo.layers)} layers, pesos copiados OK")
    return nuevo


m1 = reconstruir_float32(m1_orig, num_clases=1, model_name="model1_binary")
m2 = reconstruir_float32(m2_orig, num_clases=5, model_name="model2_pathogen")
"""),
    code("""def export_tflite(model, path, target_mb=None):
    '''Convierte modelo float32 a TFLite con cuantizacion int8 dinamica.'''
    converter = tf.lite.TFLiteConverter.from_keras_model(model)
    converter.optimizations = [tf.lite.Optimize.DEFAULT]

    print(f"  Convirtiendo {path.name}...")
    tflite_model = converter.convert()

    # Asegurar que el directorio existe
    Path(path).parent.mkdir(parents=True, exist_ok=True)
    Path(path).write_bytes(tflite_model)
    size_mb = Path(path).stat().st_size / (1024 * 1024)
    status = ""
    if target_mb:
        ok = size_mb < target_mb
        status = f" [{'OK' if ok else 'GRANDE'}]"
    print(f"    {path.name}: {size_mb:.2f} MB{status}")
    return size_mb


export_tflite(m1, OUT / "model1.tflite", target_mb=5)
export_tflite(m2, OUT / "model2.tflite", target_mb=10)
print("\\nExport completado. Copiar a Code/assets/models/")
"""),
    code("""def labels_from_indices(path_in, path_out):
    import json
    with open(path_in) as f:
        idx = json.load(f)
    sorted_labels = [k for k, _ in sorted(idx.items(), key=lambda kv: kv[1])]
    Path(path_out).write_text("\\n".join(f"{i} {lbl}" for i, lbl in enumerate(sorted_labels)))
    print(f"  {path_out}: {sorted_labels}")


labels_from_indices(OUT / "class_indices_model1_binary.json", OUT / "labels_m1.txt")
labels_from_indices(OUT / "class_indices_model2_pathogen.json", OUT / "labels_m2.txt")
"""),
    code("""# Verificar inferencia M1
inter1 = tf.lite.Interpreter(model_path=str(OUT / "model1.tflite"))
inter1.allocate_tensors()
inp1 = inter1.get_input_details()[0]
out1 = inter1.get_output_details()[0]
print("M1 Input:", inp1["shape"], inp1["dtype"])
print("M1 Output:", out1["shape"], out1["dtype"])
dummy = np.random.rand(1, 224, 224, 3).astype(np.float32)
inter1.set_tensor(inp1["index"], dummy)
inter1.invoke()
print("M1 salida prueba:", inter1.get_tensor(out1["index"]))

# Verificar inferencia M2
inter2 = tf.lite.Interpreter(model_path=str(OUT / "model2.tflite"))
inter2.allocate_tensors()
inp2 = inter2.get_input_details()[0]
out2 = inter2.get_output_details()[0]
print("M2 Input:", inp2["shape"], inp2["dtype"])
print("M2 Output:", out2["shape"], out2["dtype"])
inter2.set_tensor(inp2["index"], dummy)
inter2.invoke()
print("M2 salida prueba:", inter2.get_tensor(out2["index"]))
"""),
    md("""## Copiar a Code/

```
Code/assets/models/hs/model.tflite          <- outputs/model1.tflite
Code/assets/models/hs/labels.txt            <- outputs/labels_m1.txt
Code/assets/models/pd/model_unquant.tflite  <- outputs/model2.tflite
Code/assets/models/pd/labels.txt            <- outputs/labels_m2.txt
```
"""),
])


NB06 = make_nb([
    md("""# 06 - Demo de inferencia completa

Carga ambos modelos `.keras`, ejecuta el pipeline (sliding window + severidad + clima + onset + tratamiento) sobre una imagen real.
"""),
    code("""import sys
sys.path.append("..")
from src.inference import GlycineVisionInferencia
import cv2
import matplotlib.pyplot as plt

infer = GlycineVisionInferencia(
    ruta_modelo1="./outputs/model1_binary.keras",
    ruta_modelo2="./outputs/model2_pathogen.keras",
    ruta_clases_json="./outputs/class_indices_model2_pathogen.json",
)
"""),
    code("""IMG = "./test_image.jpg"
LAT, LON = -17.78, -63.18

res = infer.analizar(IMG, lat=LAT, lon=LON)

print("Zonas detectadas:", len(res["zonas"]))
print("Overall:", res["overall"])
print("Clima:", res["clima"])
print("Riesgo por clase:", res["riesgo_por_clase"])
print("Onset:", res["onset"])

plt.figure(figsize=(12, 8))
plt.imshow(cv2.cvtColor(res["imagen_anotada"], cv2.COLOR_BGR2RGB))
plt.axis("off")
plt.title(f"Diagnostico: {res['overall']['estado']} - dominante: {res['overall']['clase_dominante']}")
plt.tight_layout()
plt.show()
"""),
    code("""trat = res["tratamiento"]
if trat:
    print("=== TRATAMIENTO RECOMENDADO ===")
    print(f"Quimico:    {trat.get('quimico')}")
    print(f"Cultural:   {trat.get('cultural')}")
    print(f"Biologico:  {trat.get('biologico')}")
    print(f"Preventivo: {trat.get('preventivo')}")
    print(f"Urgencia:   {trat.get('urgencia')}")
"""),
])


def main():
    out = Path(__file__).parent
    pairs = [
        ("01_prepare_dataset.ipynb", NB01),
        ("02_train_model1_binary.ipynb", NB02),
        ("03_train_model2_pathogen.ipynb", NB03),
        ("04_evaluate.ipynb", NB04),
        ("05_export_tflite.ipynb", NB05),
        ("06_inference_demo.ipynb", NB06),
    ]
    for name, nb in pairs:
        with open(out / name, "w", encoding="utf-8") as f:
            json.dump(nb, f, ensure_ascii=False, indent=1)
        print("Wrote", out / name)


if __name__ == "__main__":
    main()
