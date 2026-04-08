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


def _load_tm_model(model_path: Path):
    try:
        import tensorflow as tf
        model = tf.keras.models.load_model(str(model_path), compile=False)
        return model
    except Exception:
        pass

    try:
        import tensorflow as tf
        from tensorflow.keras.layers import DepthwiseConv2D

        class PatchedDepthwiseConv2D(DepthwiseConv2D):
            def __init__(self, *args, **kwargs):
                kwargs.pop("groups", None)
                super().__init__(*args, **kwargs)

        custom_objects = {"DepthwiseConv2D": PatchedDepthwiseConv2D}
        model = tf.keras.models.load_model(
            str(model_path), compile=False, custom_objects=custom_objects
        )
        return model
    except Exception:
        pass

    try:
        os.environ["TF_USE_LEGACY_KERAS"] = "1"
        import tf_keras
        model = tf_keras.models.load_model(str(model_path), compile=False)
        return model
    except Exception:
        pass

    raise RuntimeError(
        f"No se pudo cargar {model_path}. "
        f"Intenta: pip install tf-keras o pip install tensorflow==2.15"
    )


def load_labels(labels_path: Path) -> list[str]:
    with open(labels_path, "r", encoding="utf-8") as f:
        lines = [line.strip() for line in f if line.strip()]
    cleaned = []
    for line in lines:
        parts = line.split(" ", 1)
        if len(parts) == 2 and parts[0].isdigit():
            cleaned.append(parts[1])
        else:
            cleaned.append(line)
    return cleaned


def predict_image(model, image_path: Path) -> tuple[int, float, np.ndarray]:
    try:
        from tensorflow.keras.preprocessing.image import load_img, img_to_array
    except Exception:
        from keras.preprocessing.image import load_img, img_to_array

    img = load_img(str(image_path), target_size=IMG_SIZE)
    arr = img_to_array(img) / 255.0
    arr = np.expand_dims(arr, axis=0)
    predictions = model.predict(arr, verbose=0)
    class_idx = int(np.argmax(predictions[0]))
    confidence = float(predictions[0][class_idx])
    return class_idx, confidence, predictions[0]


def build_label_mapping(labels: list[str]) -> dict[str, str]:
    mapping = {}
    group_keys = {
        "bacterial": "Bacterianas",
        "fungal": "Fungicas",
        "rust": "Roya",
        "viral": "Virales",
        "insect": "Plagas_Insectos",
        "pest": "Plagas_Insectos",
        "healthy": "Soya_Sana",
        "diseased": "Soya_Enferma",
    }
    for label in labels:
        label_lower = label.lower().replace("_", " ")
        for keyword, folder in group_keys.items():
            if keyword in label_lower:
                mapping[folder] = label
                break
    return mapping


def evaluate_model(model, labels, test_dir: Path, model_name: str, folder_to_label: dict) -> dict:
    results = {
        "model": model_name,
        "timestamp": datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
        "classes": labels,
        "per_class": {},
        "predictions": [],
    }

    n_classes = len(labels)
    confusion = np.zeros((n_classes, n_classes), dtype=int)
    total_correct = 0
    total_images = 0

    for class_dir in sorted(test_dir.iterdir()):
        if not class_dir.is_dir():
            continue

        folder_name = class_dir.name

        if folder_name in labels:
            true_label = folder_name
        elif folder_name in folder_to_label:
            true_label = folder_to_label[folder_name]
        else:
            print(f"    AVISO: carpeta '{folder_name}' no mapeada, saltando")
            continue

        if true_label not in labels:
            print(f"    AVISO: label '{true_label}' no encontrada en modelo, saltando")
            continue

        true_idx = labels.index(true_label)
        class_correct = 0
        class_total = 0

        for img_path in sorted(class_dir.glob("*.*")):
            if img_path.suffix.lower() not in config.VALID_EXTENSIONS:
                continue

            try:
                pred_idx, confidence, probs = predict_image(model, img_path)
            except Exception as e:
                print(f"    Error: {img_path.name}: {e}")
                continue

            confusion[true_idx][pred_idx] += 1
            total_images += 1
            class_total += 1

            if pred_idx == true_idx:
                total_correct += 1
                class_correct += 1

            results["predictions"].append({
                "file": str(img_path.name),
                "true_class": true_label,
                "predicted_class": labels[pred_idx],
                "confidence": round(confidence, 4),
                "correct": pred_idx == true_idx,
            })

        if class_total > 0:
            acc = class_correct / class_total
            results["per_class"][true_label] = {
                "total": class_total,
                "correct": class_correct,
                "accuracy": round(acc, 4),
            }
            print(f"    {folder_name} -> {true_label}: {class_correct}/{class_total} = {acc:.2%}")

    results["confusion_matrix"] = confusion.tolist()
    results["overall_accuracy"] = round(total_correct / total_images, 4) if total_images > 0 else 0
    results["total_images"] = total_images

    for i, label in enumerate(labels):
        tp = confusion[i][i]
        fp = sum(confusion[j][i] for j in range(n_classes)) - tp
        fn = sum(confusion[i][j] for j in range(n_classes)) - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0

        if label not in results["per_class"]:
            results["per_class"][label] = {"total": 0, "correct": 0, "accuracy": 0}
        results["per_class"][label]["precision"] = round(precision, 4)
        results["per_class"][label]["recall"] = round(recall, 4)
        results["per_class"][label]["f1"] = round(f1, 4)

    return results


def write_report(results: dict, output_dir: Path, prefix: str):
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(output_dir / f"{prefix}_metricas.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    with open(output_dir / f"{prefix}_reporte.txt", "w", encoding="utf-8") as f:
        f.write(f"{'=' * 70}\n")
        f.write(f"REPORTE DE EVALUACION - {results['model']}\n")
        f.write(f"{'=' * 70}\n")
        f.write(f"Fecha: {results['timestamp']}\n")
        f.write(f"Total imagenes evaluadas: {results['total_images']}\n")
        f.write(f"Accuracy global: {results['overall_accuracy']:.4f}\n\n")

        f.write(f"{'Clase':<25} {'Precision':>10} {'Recall':>10} {'F1':>10} {'Accuracy':>10} {'N':>6}\n")
        f.write("-" * 71 + "\n")
        for label in results["classes"]:
            pc = results["per_class"].get(label, {})
            if pc.get("total", 0) > 0:
                f.write(
                    f"{label:<25} "
                    f"{pc.get('precision', 0):>10.4f} "
                    f"{pc.get('recall', 0):>10.4f} "
                    f"{pc.get('f1', 0):>10.4f} "
                    f"{pc.get('accuracy', 0):>10.4f} "
                    f"{pc.get('total', 0):>6}\n"
                )

        f.write(f"\nMatriz de confusion (filas=real, columnas=prediccion):\n\n")
        labels = results["classes"]
        max_len = max(len(l[:18]) for l in labels)
        header = " " * (max_len + 2) + "  ".join(f"{l[:12]:>12}" for l in labels)
        f.write(header + "\n")
        for i, row in enumerate(results["confusion_matrix"]):
            line = f"{labels[i][:max_len]:<{max_len + 2}}" + "  ".join(f"{v:>12}" for v in row)
            f.write(line + "\n")

    with open(output_dir / f"{prefix}_predicciones.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["file", "true_class", "predicted_class", "confidence", "correct"])
        writer.writeheader()
        writer.writerows(results["predictions"])

    print(f"    Guardado: {output_dir / prefix}_*.{{json,txt,csv}}")


def main():
    print("=" * 60)
    print("EVALUACION DE MODELOS KERAS CON TEST SET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    hs_dir = MODELS_DIR / "glycine-vision-hs"
    pd_dir = MODELS_DIR / "glycine-vision-pd"

    if hs_dir.exists() and (hs_dir / "keras_model.h5").exists():
        print("\n  MODELO 1: Sana vs Enferma")
        print(f"    Cargando {hs_dir / 'keras_model.h5'}...")
        model1 = _load_tm_model(hs_dir / "keras_model.h5")
        labels1 = load_labels(hs_dir / "labels.txt")
        print(f"    Labels: {labels1}")

        folder_map1 = build_label_mapping(labels1)
        print(f"    Mapeo: {folder_map1}")

        results1 = evaluate_model(model1, labels1, TEST_DIR, "Modelo1_Sana_Enferma", folder_map1)
        write_report(results1, REPORT_DIR, "modelo1")
        print(f"    Accuracy global: {results1['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 1 no encontrado en {hs_dir}")

    if pd_dir.exists() and (pd_dir / "keras_model.h5").exists():
        print("\n  MODELO 2: Tipo de Patogeno")
        print(f"    Cargando {pd_dir / 'keras_model.h5'}...")
        model2 = _load_tm_model(pd_dir / "keras_model.h5")
        labels2 = load_labels(pd_dir / "labels.txt")
        print(f"    Labels: {labels2}")

        folder_map2 = build_label_mapping(labels2)
        print(f"    Mapeo: {folder_map2}")

        results2 = evaluate_model(model2, labels2, TEST_DIR, "Modelo2_Tipo_Patogeno", folder_map2)
        write_report(results2, REPORT_DIR, "modelo2")
        print(f"    Accuracy global: {results2['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 2 no encontrado en {pd_dir}")

    print(f"\n  Reportes en: {REPORT_DIR}")


if __name__ == "__main__":
    main()
