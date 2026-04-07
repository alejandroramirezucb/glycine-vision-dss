import json
import csv
from pathlib import Path
from datetime import datetime

import numpy as np

try:
    from tensorflow.keras.models import load_model
    from tensorflow.keras.preprocessing.image import load_img, img_to_array
except ImportError:
    from keras.models import load_model
    from keras.preprocessing.image import load_img, img_to_array

import config

MODELS_DIR = Path(r"C:\Users\USUARIO\Documents\5_SEMESTRE\IA\glycine-vision-dss\Models")
TEST_DIR = config.BASE_DIR / "test_set"
REPORT_DIR = config.BASE_DIR / "evaluacion"
IMG_SIZE = (224, 224)


def load_labels(labels_path: Path) -> list[str]:
    with open(labels_path, "r", encoding="utf-8") as f:
        return [line.strip() for line in f if line.strip()]


def predict_image(model, image_path: Path) -> tuple[int, float, np.ndarray]:
    img = load_img(str(image_path), target_size=IMG_SIZE)
    arr = img_to_array(img) / 255.0
    arr = np.expand_dims(arr, axis=0)
    predictions = model.predict(arr, verbose=0)
    class_idx = int(np.argmax(predictions[0]))
    confidence = float(predictions[0][class_idx])
    return class_idx, confidence, predictions[0]


def evaluate_model(model, labels, test_dir: Path, model_name: str) -> dict:
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

        class_name = class_dir.name
        if class_name not in labels:
            print(f"    AVISO: {class_name} no esta en labels, saltando")
            continue

        true_idx = labels.index(class_name)
        class_correct = 0
        class_total = 0

        for img_path in sorted(class_dir.glob("*.*")):
            if img_path.suffix.lower() not in config.VALID_EXTENSIONS:
                continue

            try:
                pred_idx, confidence, probs = predict_image(model, img_path)
            except Exception as e:
                print(f"    Error en {img_path.name}: {e}")
                continue

            confusion[true_idx][pred_idx] += 1
            total_images += 1
            class_total += 1

            if pred_idx == true_idx:
                total_correct += 1
                class_correct += 1

            results["predictions"].append({
                "file": str(img_path.name),
                "true_class": class_name,
                "predicted_class": labels[pred_idx],
                "confidence": round(confidence, 4),
                "correct": pred_idx == true_idx,
            })

        if class_total > 0:
            acc = class_correct / class_total
            results["per_class"][class_name] = {
                "total": class_total,
                "correct": class_correct,
                "accuracy": round(acc, 4),
            }
            print(f"    {class_name}: {class_correct}/{class_total} = {acc:.2%}")

    results["confusion_matrix"] = confusion.tolist()
    results["overall_accuracy"] = round(total_correct / total_images, 4) if total_images > 0 else 0
    results["total_images"] = total_images

    precision_per_class = {}
    recall_per_class = {}
    f1_per_class = {}

    for i, label in enumerate(labels):
        tp = confusion[i][i]
        fp = sum(confusion[j][i] for j in range(n_classes)) - tp
        fn = sum(confusion[i][j] for j in range(n_classes)) - tp
        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * precision * recall / (precision + recall) if (precision + recall) > 0 else 0
        precision_per_class[label] = round(precision, 4)
        recall_per_class[label] = round(recall, 4)
        f1_per_class[label] = round(f1, 4)

    results["precision"] = precision_per_class
    results["recall"] = recall_per_class
    results["f1_score"] = f1_per_class

    return results


def write_report(results: dict, output_dir: Path, prefix: str):
    output_dir.mkdir(parents=True, exist_ok=True)

    with open(output_dir / f"{prefix}_metricas.json", "w", encoding="utf-8") as f:
        json.dump(results, f, indent=2, ensure_ascii=False)

    with open(output_dir / f"{prefix}_reporte.txt", "w", encoding="utf-8") as f:
        f.write(f"{'=' * 60}\n")
        f.write(f"REPORTE DE EVALUACION - {results['model']}\n")
        f.write(f"{'=' * 60}\n")
        f.write(f"Fecha: {results['timestamp']}\n")
        f.write(f"Total imagenes: {results['total_images']}\n")
        f.write(f"Accuracy global: {results['overall_accuracy']:.4f}\n\n")

        f.write(f"{'Clase':<25} {'Precision':<12} {'Recall':<12} {'F1':<12} {'Accuracy':<12} {'N':<6}\n")
        f.write("-" * 79 + "\n")
        for label in results["classes"]:
            if label in results["per_class"]:
                pc = results["per_class"][label]
                p = results["precision"].get(label, 0)
                r = results["recall"].get(label, 0)
                f1 = results["f1_score"].get(label, 0)
                f.write(f"{label:<25} {p:<12.4f} {r:<12.4f} {f1:<12.4f} {pc['accuracy']:<12.4f} {pc['total']:<6}\n")

        f.write(f"\nMatriz de confusion:\n")
        labels = results["classes"]
        header = f"{'':>20}" + "".join(f"{l[:15]:>16}" for l in labels)
        f.write(header + "\n")
        for i, row in enumerate(results["confusion_matrix"]):
            line = f"{labels[i][:20]:>20}" + "".join(f"{v:>16}" for v in row)
            f.write(line + "\n")

    with open(output_dir / f"{prefix}_predicciones.csv", "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=["file", "true_class", "predicted_class", "confidence", "correct"])
        writer.writeheader()
        writer.writerows(results["predictions"])


def main():
    print("=" * 60)
    print("EVALUACION DE MODELOS KERAS CON TEST SET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 60)

    REPORT_DIR.mkdir(parents=True, exist_ok=True)

    hs_dir = MODELS_DIR / "glycine-vision-hs"
    pd_dir = MODELS_DIR / "glycine-vision-pd"

    if hs_dir.exists() and (hs_dir / "keras_model.h5").exists():
        print("\n  MODELO 1: Sana vs Enferma (glycine-vision-hs)")
        model1 = load_model(str(hs_dir / "keras_model.h5"), compile=False)
        labels1 = load_labels(hs_dir / "labels.txt")
        print(f"    Labels: {labels1}")

        test1 = TEST_DIR.parent / "test_set_m1"
        if not test1.exists():
            test1 = TEST_DIR
            print(f"    Usando test_set general (mapear Soya_Sana->healthy, grupos->diseased)")

        results1 = evaluate_model(model1, labels1, test1, "Modelo1_Sana_Enferma")
        write_report(results1, REPORT_DIR, "modelo1")
        print(f"    Accuracy global: {results1['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 1 no encontrado en {hs_dir}")

    if pd_dir.exists() and (pd_dir / "keras_model.h5").exists():
        print("\n  MODELO 2: Tipo de Patogeno (glycine-vision-pd)")
        model2 = load_model(str(pd_dir / "keras_model.h5"), compile=False)
        labels2 = load_labels(pd_dir / "labels.txt")
        print(f"    Labels: {labels2}")

        label_map = {}
        for label in labels2:
            for group in config.DISEASE_GROUPS:
                if group.lower().replace("_", "") in label.lower().replace("_", ""):
                    label_map[group] = label
                    break

        test2 = TEST_DIR
        if label_map:
            print(f"    Mapeo carpetas->labels: {label_map}")

        results2 = evaluate_model(model2, labels2, test2, "Modelo2_Tipo_Patogeno")
        write_report(results2, REPORT_DIR, "modelo2")
        print(f"    Accuracy global: {results2['overall_accuracy']:.2%}")
    else:
        print(f"\n  Modelo 2 no encontrado en {pd_dir}")

    print(f"\n  Reportes en: {REPORT_DIR}")
    print(f"  Archivos generados:")
    print(f"    *_metricas.json  -> datos completos para KNIME o analisis")
    print(f"    *_reporte.txt    -> tabla formateada para el documento")
    print(f"    *_predicciones.csv -> cada prediccion individual")


if __name__ == "__main__":
    main()
