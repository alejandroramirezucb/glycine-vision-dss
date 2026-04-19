"""
evaluate_model.py — Evaluación en cascada de Modelo 1 y Modelo 2.

Lógica de evaluación:
  - Modelo 1 (Sana/Enferma): evalúa TODAS las carpetas del test set.
      Soya_Sana  -> debe predecir "Soya_Sana"   (o equivalente)
      Bacterianas, Fungicas, Roya, Virales, Plagas_Insectos
                 -> deben predecir "Soya_Enferma" (o equivalente)

  - Modelo 2 (Tipo de Patógeno): evalúa SOLO las carpetas de enfermedades.
      Bacterianas -> debe predecir "Bacterianas"
      Fungicas    -> debe predecir "Fungicas"
      etc.

  - Evaluación cascada: imagen sana bien clasificada en M1 + imagen enferma
    bien clasificada en M1 Y correctamente tipificada en M2 = éxito total.
"""
import os
import json
import csv
from pathlib import Path
from datetime import datetime

os.environ["TF_CPP_MIN_LOG_LEVEL"] = "2"

import numpy as np

import config

MODELS_DIR = Path(r"C:\Users\USUARIO\Documents\5_SEMESTRE\IA\glycine-vision-dss\Models")
TEST_DIR = config.BASE_DIR / "test_set"
REPORT_DIR = config.BASE_DIR / "evaluacion"
IMG_SIZE = (224, 224)

# Carpetas del test set y su clase verdadera para cada modelo
# Modelo 1: todas las carpetas de enfermedades mapean a "Soya_Enferma"
DISEASE_FOLDERS = list(config.DISEASE_GROUPS.keys())  # ["Bacterianas", "Fungicas", ...]

# Palabras clave para identificar las labels del modelo 1
M1_HEALTHY_KEYWORDS = {"healthy", "sana", "soya_sana"}
M1_DISEASED_KEYWORDS = {"diseased", "enferma", "soya_enferma"}

# Palabras clave para mapear labels del modelo 2 a carpetas del test set
M2_LABEL_TO_FOLDER = {
    "bacterian": "Bacterianas",
    "bacterial": "Bacterianas",
    "fungic": "Fungicas",
    "fungal": "Fungicas",
    "roya": "Roya",
    "rust": "Roya",
    "viral": "Virales",
    "virus": "Virales",
    "mosaic": "Virales",
    "plaga": "Plagas_Insectos",
    "insect": "Plagas_Insectos",
    "pest": "Plagas_Insectos",
}


# ══════════════════════════════════════════════════════════════════════════════
# Carga del modelo
# ══════════════════════════════════════════════════════════════════════════════

def _load_tm_model(model_path: Path):
    """Carga un modelo Keras de Teachable Machine con múltiples fallbacks."""
    # Intento 1: carga directa
    try:
        import tensorflow as tf
        return tf.keras.models.load_model(str(model_path), compile=False)
    except Exception:
        pass

    # Intento 2: parchear DepthwiseConv2D (problema de compatibilidad TF)
    try:
        import tensorflow as tf
        from tensorflow.keras.layers import DepthwiseConv2D

        class PatchedDepthwiseConv2D(DepthwiseConv2D):
            def __init__(self, *args, **kwargs):
                kwargs.pop("groups", None)
                super().__init__(*args, **kwargs)

        return tf.keras.models.load_model(
            str(model_path), compile=False,
            custom_objects={"DepthwiseConv2D": PatchedDepthwiseConv2D}
        )
    except Exception:
        pass

    # Intento 3: tf-keras legacy
    try:
        os.environ["TF_USE_LEGACY_KERAS"] = "1"
        import tf_keras
        return tf_keras.models.load_model(str(model_path), compile=False)
    except Exception:
        pass

    raise RuntimeError(
        f"No se pudo cargar {model_path}.\n"
        "Prueba: pip install tf-keras  o  pip install tensorflow==2.15"
    )


def load_labels(labels_path: Path) -> list[str]:
    """Lee labels.txt de Teachable Machine (formato '0 NombreClase')."""
    with open(labels_path, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]
    cleaned = []
    for line in lines:
        parts = line.split(" ", 1)
        cleaned.append(parts[1] if (len(parts) == 2 and parts[0].isdigit()) else line)
    return cleaned


# ══════════════════════════════════════════════════════════════════════════════
# Inferencia
# ══════════════════════════════════════════════════════════════════════════════

def predict_image(model, image_path: Path) -> tuple[int, float, np.ndarray]:
    try:
        from tensorflow.keras.preprocessing.image import load_img, img_to_array
    except Exception:
        from keras.preprocessing.image import load_img, img_to_array

    img = load_img(str(image_path), target_size=IMG_SIZE)
    arr = img_to_array(img) / 255.0
    arr = np.expand_dims(arr, axis=0)
    preds = model.predict(arr, verbose=0)
    idx = int(np.argmax(preds[0]))
    return idx, float(preds[0][idx]), preds[0]


# ══════════════════════════════════════════════════════════════════════════════
# Detección automática de labels
# ══════════════════════════════════════════════════════════════════════════════

def detect_m1_labels(labels: list[str]) -> tuple[str | None, str | None]:
    """Devuelve (label_sana, label_enferma) detectadas por palabras clave."""
    label_sana = label_enferma = None
    for lbl in labels:
        low = lbl.lower().replace("_", " ")
        if any(k in low for k in M1_HEALTHY_KEYWORDS):
            label_sana = lbl
        elif any(k in low for k in M1_DISEASED_KEYWORDS):
            label_enferma = lbl
    return label_sana, label_enferma


def detect_m2_label_map(labels: list[str]) -> dict[str, str]:
    """Devuelve {carpeta_test: label_modelo2} para el modelo de patógenos."""
    mapping = {}
    for lbl in labels:
        low = lbl.lower().replace("_", " ")
        for keyword, folder in M2_LABEL_TO_FOLDER.items():
            if keyword in low and folder not in mapping:
                mapping[folder] = lbl
                break
    return mapping


# ══════════════════════════════════════════════════════════════════════════════
# Evaluación Modelo 1 (Sana / Enferma)
# ══════════════════════════════════════════════════════════════════════════════

def evaluate_m1(model, labels: list[str], test_dir: Path) -> dict:
    """
    Evalúa el Modelo 1 sobre todas las carpetas del test set.

    Regla de mapeo:
      carpeta "Soya_Sana"               -> verdadero = label_sana
      carpetas de enfermedad (5 grupos) -> verdadero = label_enferma
    """
    label_sana, label_enferma = detect_m1_labels(labels)
    if not label_sana or not label_enferma:
        print(f"    AVISO: no se detectaron labels sana/enferma. Labels: {labels}")
        print("    Asegúrate de que tus labels contengan 'healthy'/'sana' y 'diseased'/'enferma'.")
        return {}

    print(f"    Label sana   detectada: '{label_sana}'")
    print(f"    Label enferma detectada: '{label_enferma}'")

    results = {
        "model": "Modelo1_Sana_Enferma",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "classes": labels,
        "label_sana": label_sana,
        "label_enferma": label_enferma,
        "per_folder": {},
        "predictions": [],
    }

    n_classes = len(labels)
    confusion = np.zeros((n_classes, n_classes), dtype=int)
    total_correct = total_images = 0

    for class_dir in sorted(test_dir.iterdir()):
        if not class_dir.is_dir():
            continue

        folder = class_dir.name
        if folder == "Soya_Sana":
            true_label = label_sana
        elif folder in DISEASE_FOLDERS:
            true_label = label_enferma
        else:
            print(f"    AVISO: carpeta '{folder}' ignorada (no es Soya_Sana ni grupo de enfermedad)")
            continue

        true_idx = labels.index(true_label)
        folder_correct = folder_total = 0

        for img_path in sorted(class_dir.glob("*.*")):
            if img_path.suffix.lower() not in config.VALID_EXTENSIONS:
                continue
            try:
                pred_idx, confidence, probs = predict_image(model, img_path)
            except Exception as e:
                print(f"      Error {img_path.name}: {e}")
                continue

            confusion[true_idx][pred_idx] += 1
            total_images += 1
            folder_total += 1
            correct = pred_idx == true_idx
            if correct:
                total_correct += 1
                folder_correct += 1

            results["predictions"].append({
                "file": img_path.name,
                "folder": folder,
                "true_label": true_label,
                "predicted_label": labels[pred_idx],
                "confidence": round(confidence, 4),
                "correct": correct,
            })

        if folder_total > 0:
            acc = folder_correct / folder_total
            results["per_folder"][folder] = {
                "true_label": true_label,
                "total": folder_total,
                "correct": folder_correct,
                "accuracy": round(acc, 4),
            }
            print(f"    {folder:25s} -> {true_label}: {folder_correct}/{folder_total} = {acc:.2%}")

    # Métricas globales y por clase
    results["confusion_matrix"] = confusion.tolist()
    results["overall_accuracy"] = round(total_correct / total_images, 4) if total_images > 0 else 0
    results["total_images"] = total_images

    for i, lbl in enumerate(labels):
        tp = confusion[i][i]
        fp = sum(confusion[j][i] for j in range(n_classes)) - tp
        fn = sum(confusion[i][j] for j in range(n_classes)) - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall    = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        results.setdefault("per_class", {})[lbl] = {
            "precision": round(precision, 4),
            "recall":    round(recall, 4),
            "f1":        round(f1, 4),
            "total": int(sum(confusion[i])),
        }

    return results


# ══════════════════════════════════════════════════════════════════════════════
# Evaluación Modelo 2 (Tipo de Patógeno)
# ══════════════════════════════════════════════════════════════════════════════

def evaluate_m2(model, labels: list[str], test_dir: Path) -> dict:
    """
    Evalúa el Modelo 2 SOLO sobre carpetas de enfermedades.
    Soya_Sana se omite (el M2 no debe ver imágenes sanas).
    """
    folder_to_label = detect_m2_label_map(labels)
    print(f"    Mapeo carpeta -> label: {folder_to_label}")

    results = {
        "model": "Modelo2_Tipo_Patogeno",
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "classes": labels,
        "folder_to_label": folder_to_label,
        "per_folder": {},
        "predictions": [],
    }

    n_classes = len(labels)
    confusion = np.zeros((n_classes, n_classes), dtype=int)
    total_correct = total_images = 0

    for class_dir in sorted(test_dir.iterdir()):
        if not class_dir.is_dir():
            continue

        folder = class_dir.name
        if folder == "Soya_Sana":
            continue  # El M2 no evalúa hojas sanas
        if folder not in DISEASE_FOLDERS:
            print(f"    AVISO: carpeta '{folder}' ignorada")
            continue
        if folder not in folder_to_label:
            print(f"    AVISO: carpeta '{folder}' sin label en el modelo (faltan keywords?)")
            continue

        true_label = folder_to_label[folder]
        true_idx = labels.index(true_label)
        folder_correct = folder_total = 0

        for img_path in sorted(class_dir.glob("*.*")):
            if img_path.suffix.lower() not in config.VALID_EXTENSIONS:
                continue
            try:
                pred_idx, confidence, probs = predict_image(model, img_path)
            except Exception as e:
                print(f"      Error {img_path.name}: {e}")
                continue

            confusion[true_idx][pred_idx] += 1
            total_images += 1
            folder_total += 1
            correct = pred_idx == true_idx
            if correct:
                total_correct += 1
                folder_correct += 1

            results["predictions"].append({
                "file": img_path.name,
                "folder": folder,
                "true_label": true_label,
                "predicted_label": labels[pred_idx],
                "confidence": round(confidence, 4),
                "correct": correct,
            })

        if folder_total > 0:
            acc = folder_correct / folder_total
            results["per_folder"][folder] = {
                "true_label": true_label,
                "total": folder_total,
                "correct": folder_correct,
                "accuracy": round(acc, 4),
            }
            print(f"    {folder:25s} -> {true_label}: {folder_correct}/{folder_total} = {acc:.2%}")

    results["confusion_matrix"] = confusion.tolist()
    results["overall_accuracy"] = round(total_correct / total_images, 4) if total_images > 0 else 0
    results["total_images"] = total_images

    for i, lbl in enumerate(labels):
        tp = confusion[i][i]
        fp = sum(confusion[j][i] for j in range(n_classes)) - tp
        fn = sum(confusion[i][j] for j in range(n_classes)) - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall    = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        results.setdefault("per_class", {})[lbl] = {
            "precision": round(precision, 4),
            "recall":    round(recall, 4),
            "f1":        round(f1, 4),
            "total": int(sum(confusion[i])),
        }

    return results


# ══════════════════════════════════════════════════════════════════════════════
# Evaluación en cascada
# ══════════════════════════════════════════════════════════════════════════════

def evaluate_cascade(model1, labels1, model2, labels2, test_dir: Path) -> dict:
    """
    Recorre TODAS las imágenes del test set y simula el flujo real de la app:
      1. M1 clasifica sana/enferma.
      2. Si M1 dice "enferma", M2 clasifica el tipo de patógeno.

    Métricas reportadas:
      - M1 accuracy (sana vs enferma)
      - M2 accuracy (tipo de patógeno, solo sobre las enfermas)
      - Cascada accuracy: % de imágenes donde AMBOS modelos aciertan
    """
    label_sana, label_enferma = detect_m1_labels(labels1)
    folder_to_label_m2 = detect_m2_label_map(labels2)

    cascade_rows = []
    m1_total = m1_correct = 0
    m2_total = m2_correct = 0
    cascade_total = cascade_correct = 0

    for class_dir in sorted(test_dir.iterdir()):
        if not class_dir.is_dir():
            continue

        folder = class_dir.name
        is_sana = (folder == "Soya_Sana")
        is_disease = folder in DISEASE_FOLDERS

        if not is_sana and not is_disease:
            continue

        true_m2_label = folder_to_label_m2.get(folder) if is_disease else None

        for img_path in sorted(class_dir.glob("*.*")):
            if img_path.suffix.lower() not in config.VALID_EXTENSIONS:
                continue

            # ── Paso 1: Modelo 1 ────────────────────────────────────────────
            try:
                pred_idx1, conf1, _ = predict_image(model1, img_path)
            except Exception:
                continue

            pred_label1 = labels1[pred_idx1]
            m1_pred_is_sana = any(k in pred_label1.lower() for k in M1_HEALTHY_KEYWORDS)
            m1_pred_is_enf  = any(k in pred_label1.lower() for k in M1_DISEASED_KEYWORDS)

            true_m1_label = label_sana if is_sana else label_enferma
            m1_ok = (pred_label1 == true_m1_label)
            m1_total += 1
            if m1_ok:
                m1_correct += 1

            # ── Paso 2: Modelo 2 (solo si M1 predijo enferma y la imagen ES enferma) ──
            pred_label2 = conf2 = m2_ok = None
            if is_disease and m1_pred_is_enf:
                try:
                    pred_idx2, conf2, _ = predict_image(model2, img_path)
                    pred_label2 = labels2[pred_idx2]
                    m2_ok = (pred_label2 == true_m2_label)
                    m2_total += 1
                    if m2_ok:
                        m2_correct += 1
                except Exception:
                    pass

            # ── Cascada ─────────────────────────────────────────────────────
            if is_sana:
                # Sana: solo necesita que M1 acierte
                cascade_total += 1
                if m1_ok:
                    cascade_correct += 1
            else:
                # Enferma: M1 debe decir "enferma" Y M2 debe acertar el tipo
                cascade_total += 1
                if m1_ok and m2_ok:
                    cascade_correct += 1

            cascade_rows.append({
                "file": img_path.name,
                "folder": folder,
                "m1_true": true_m1_label,
                "m1_pred": pred_label1,
                "m1_conf": round(conf1, 4),
                "m1_ok": m1_ok,
                "m2_true": true_m2_label or "",
                "m2_pred": pred_label2 or "",
                "m2_conf": round(conf2, 4) if conf2 else "",
                "m2_ok": m2_ok if m2_ok is not None else "",
                "cascade_ok": (m1_ok and (m2_ok if m2_ok is not None else True)) if not is_sana else m1_ok,
            })

    return {
        "m1_accuracy": round(m1_correct / m1_total, 4) if m1_total else 0,
        "m1_total": m1_total,
        "m2_accuracy": round(m2_correct / m2_total, 4) if m2_total else 0,
        "m2_total": m2_total,
        "cascade_accuracy": round(cascade_correct / cascade_total, 4) if cascade_total else 0,
        "cascade_total": cascade_total,
        "rows": cascade_rows,
    }


# ══════════════════════════════════════════════════════════════════════════════
# Escritura de reportes
# ══════════════════════════════════════════════════════════════════════════════

def write_report(results: dict, output_dir: Path, prefix: str):
    output_dir.mkdir(parents=True, exist_ok=True)

    # JSON completo
    with open(output_dir / f"{prefix}_metricas.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    # TXT legible
    with open(output_dir / f"{prefix}_reporte.txt", "w", encoding="utf-8") as f:
        f.write(f"{'=' * 70}\n")
        f.write(f"REPORTE - {results.get('model', prefix)}\n")
        f.write(f"{'=' * 70}\n")
        f.write(f"Fecha:    {results.get('timestamp', '')}\n")
        f.write(f"Imagenes: {results.get('total_images', 0)}\n")
        f.write(f"Accuracy: {results.get('overall_accuracy', 0):.4f}\n\n")

        # Por carpeta
        if results.get("per_folder"):
            f.write(f"{'Carpeta':<25} {'Label real':<20} {'Prec':>6} {'Rec':>6} {'N':>5}\n")
            f.write("-" * 65 + "\n")
            for folder, d in results["per_folder"].items():
                f.write(f"{folder:<25} {d['true_label']:<20} {d['accuracy']:>6.4f} {d['total']:>5}\n")

        # Por clase
        f.write(f"\n{'Clase':<25} {'Precision':>10} {'Recall':>10} {'F1':>10}\n")
        f.write("-" * 57 + "\n")
        for lbl, pc in results.get("per_class", {}).items():
            f.write(
                f"{lbl:<25} "
                f"{pc.get('precision', 0):>10.4f} "
                f"{pc.get('recall', 0):>10.4f} "
                f"{pc.get('f1', 0):>10.4f}\n"
            )

        # Matriz de confusión
        labels = results.get("classes", [])
        matrix = results.get("confusion_matrix", [])
        if labels and matrix:
            f.write("\nMatriz de confusion (filas=real, columnas=prediccion):\n\n")
            max_len = max(len(l[:20]) for l in labels)
            header = " " * (max_len + 2) + "  ".join(f"{l[:12]:>12}" for l in labels)
            f.write(header + "\n")
            for i, row in enumerate(matrix):
                line = f"{labels[i][:max_len]:<{max_len + 2}}" + "  ".join(f"{v:>12}" for v in row)
                f.write(line + "\n")

    # CSV de predicciones individuales
    preds = results.get("predictions", [])
    if preds:
        fieldnames = list(preds[0].keys())
        with open(output_dir / f"{prefix}_predicciones.csv", "w", newline="", encoding="utf-8") as f:
            writer = csv.DictWriter(f, fieldnames=fieldnames)
            writer.writeheader()
            writer.writerows(preds)

    print(f"    Guardado: {output_dir}/{prefix}_*.{{json,txt,csv}}")


def write_cascade_report(cascade: dict, output_dir: Path):
    output_dir.mkdir(parents=True, exist_ok=True)
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")

    with open(output_dir / "cascada_resumen.txt", "w", encoding="utf-8") as f:
        f.write(f"{'=' * 60}\n")
        f.write("REPORTE DE EVALUACION EN CASCADA\n")
        f.write(f"{'=' * 60}\n")
        f.write(f"Fecha: {ts}\n\n")
        f.write(f"Modelo 1 (Sana/Enferma)\n")
        f.write(f"  Imagenes evaluadas: {cascade['m1_total']}\n")
        f.write(f"  Accuracy:           {cascade['m1_accuracy']:.4f} ({cascade['m1_accuracy']*100:.2f}%)\n\n")
        f.write(f"Modelo 2 (Tipo de Patogeno)\n")
        f.write(f"  Imagenes evaluadas: {cascade['m2_total']}\n")
        f.write(f"  Accuracy:           {cascade['m2_accuracy']:.4f} ({cascade['m2_accuracy']*100:.2f}%)\n\n")
        f.write(f"Precision en cascada (M1 + M2 correctos)\n")
        f.write(f"  Imagenes evaluadas: {cascade['cascade_total']}\n")
        f.write(f"  Accuracy cascada:   {cascade['cascade_accuracy']:.4f} ({cascade['cascade_accuracy']*100:.2f}%)\n")

    with open(output_dir / "cascada_predicciones.csv", "w", newline="", encoding="utf-8") as f:
        if cascade["rows"]:
            writer = csv.DictWriter(f, fieldnames=list(cascade["rows"][0].keys()))
            writer.writeheader()
            writer.writerows(cascade["rows"])

    print(f"    Cascada guardada en {output_dir}/cascada_*.{{txt,csv}}")


# ══════════════════════════════════════════════════════════════════════════════
# Main
# ══════════════════════════════════════════════════════════════════════════════

def main():
    print("=" * 60)
    print("EVALUACION DE MODELOS KERAS CON TEST SET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    hs_dir = MODELS_DIR / "glycine-vision-hs"
    pd_dir = MODELS_DIR / "glycine-vision-pd"

    model1 = labels1 = None
    model2 = labels2 = None

    # ── Modelo 1 ──────────────────────────────────────────────────────────
    if hs_dir.exists() and (hs_dir / "keras_model.h5").exists():
        print(f"\n  MODELO 1: Sana vs Enferma")
        print(f"    Cargando {hs_dir / 'keras_model.h5'} ...")
        model1 = _load_tm_model(hs_dir / "keras_model.h5")
        labels1 = load_labels(hs_dir / "labels.txt")
        print(f"    Labels: {labels1}")

        results1 = evaluate_m1(model1, labels1, TEST_DIR)
        if results1:
            write_report(results1, REPORT_DIR, "modelo1")
            print(f"    Accuracy global: {results1['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 1 no encontrado en {hs_dir}")

    # ── Modelo 2 ──────────────────────────────────────────────────────────
    if pd_dir.exists() and (pd_dir / "keras_model.h5").exists():
        print(f"\n  MODELO 2: Tipo de Patogeno")
        print(f"    Cargando {pd_dir / 'keras_model.h5'} ...")
        model2 = _load_tm_model(pd_dir / "keras_model.h5")
        labels2 = load_labels(pd_dir / "labels.txt")
        print(f"    Labels: {labels2}")

        results2 = evaluate_m2(model2, labels2, TEST_DIR)
        if results2:
            write_report(results2, REPORT_DIR, "modelo2")
            print(f"    Accuracy global: {results2['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 2 no encontrado en {pd_dir}")

    # ── Evaluación en cascada ──────────────────────────────────────────────
    if model1 and model2 and labels1 and labels2:
        print(f"\n  EVALUACION EN CASCADA (flujo real de la app)")
        cascade = evaluate_cascade(model1, labels1, model2, labels2, TEST_DIR)
        write_cascade_report(cascade, REPORT_DIR)
        print(f"\n  ┌─────────────────────────────────────────────┐")
        print(f"  │  M1 accuracy:      {cascade['m1_accuracy']:.4f} ({cascade['m1_accuracy']*100:.1f}%)          │")
        print(f"  │  M2 accuracy:      {cascade['m2_accuracy']:.4f} ({cascade['m2_accuracy']*100:.1f}%)          │")
        print(f"  │  Cascada accuracy: {cascade['cascade_accuracy']:.4f} ({cascade['cascade_accuracy']*100:.1f}%)          │")
        print(f"  └─────────────────────────────────────────────┘")

    print(f"\n  Reportes en: {REPORT_DIR}")


if __name__ == "__main__":
    main()
