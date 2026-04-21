import numpy as np
from pathlib import Path
from PIL import Image
import openpyxl
from openpyxl.styles import PatternFill, Font
from tensorflow.keras.models import load_model
from config import (
    test_folder, model_m1_path, model_m2_path, batch_size,
    archivo_excel_salida_m1, archivo_excel_salida_m2,
    disease_classes_m2, binary_classes_m1
)

class PatchedDepthwiseConv2D:
    pass

def load_model_with_fallback(model_path):
    try:
        return load_model(str(model_path))
    except:
        try:
            custom_objects = {"DepthwiseConv2D": PatchedDepthwiseConv2D}
            return load_model(str(model_path), custom_objects=custom_objects)
        except:
            import tensorflow as tf
            return tf.keras.models.load_model(str(model_path))

def load_images_from_folder(folder_path, target_size=(224, 224)):
    images = []
    for img_file in folder_path.rglob("*"):
        if img_file.is_file() and img_file.suffix.lower() in {".jpg", ".jpeg", ".png"}:
            try:
                img = Image.open(img_file).convert("RGB")
                img = img.resize(target_size)
                images.append(np.array(img) / 255.0)
            except:
                pass
    return np.array(images)

def predict_batch(model, images, batch_size=32):
    predictions = []
    for i in range(0, len(images), batch_size):
        batch = images[i:i+batch_size]
        batch_predictions = model.predict(batch, verbose=0)
        predictions.extend(batch_predictions)
    return np.array(predictions)

def calculate_metrics(true_labels, predictions):
    predicted_labels = np.argmax(predictions, axis=1)
    accuracy = np.mean(true_labels == predicted_labels)

    precision_list = []
    recall_list = []
    f1_list = []

    for class_idx in range(len(np.unique(true_labels))):
        tp = np.sum((predicted_labels == class_idx) & (true_labels == class_idx))
        fp = np.sum((predicted_labels == class_idx) & (true_labels != class_idx))
        fn = np.sum((predicted_labels != class_idx) & (true_labels == class_idx))

        precision = tp / (tp + fp) if (tp + fp) > 0 else 0
        recall = tp / (tp + fn) if (tp + fn) > 0 else 0
        f1 = 2 * (precision * recall) / (precision + recall) if (precision + recall) > 0 else 0

        precision_list.append(precision)
        recall_list.append(recall)
        f1_list.append(f1)

    return accuracy, precision_list, recall_list, f1_list

def write_excel(output_path, class_names, accuracies, precisions, recalls, f1_scores):
    wb = openpyxl.Workbook()
    ws = wb.active
    ws.title = "Results"

    header_fill = PatternFill(start_color="0070C0", end_color="0070C0", fill_type="solid")
    header_font = Font(bold=True, color="FFFFFF")

    ws["A1"] = "Class"
    ws["B1"] = "Test Images"
    ws["C1"] = "Accuracy"
    ws["D1"] = "Precision"
    ws["E1"] = "Recall"
    ws["F1"] = "F1-Score"

    for col in ["A1", "B1", "C1", "D1", "E1", "F1"]:
        ws[col].fill = header_fill
        ws[col].font = header_font

    for idx, class_name in enumerate(class_names):
        row = idx + 2
        ws[f"A{row}"] = class_name
        ws[f"B{row}"] = len(accuracies[idx])
        ws[f"C{row}"] = accuracies[idx] * 100
        ws[f"D{row}"] = precisions[idx]
        ws[f"E{row}"] = recalls[idx]
        ws[f"F{row}"] = f1_scores[idx]

        accuracy_val = accuracies[idx] * 100
        fill_color = "00B050" if accuracy_val >= 90 else "FFEB9C" if accuracy_val >= 70 else "FF0000"
        ws[f"C{row}"].fill = PatternFill(start_color=fill_color, end_color=fill_color, fill_type="solid")

    summary_row = len(class_names) + 3
    ws[f"A{summary_row}"] = "Overall"
    ws[f"C{summary_row}"] = np.mean(accuracies) * 100
    ws[f"C{summary_row}"].fill = PatternFill(start_color="D3D3D3", end_color="D3D3D3", fill_type="solid")

    for col in ["A", "B", "C", "D", "E", "F"]:
        ws.column_dimensions[col].width = 15

    wb.save(output_path)

def evaluate_m1():
    print("\n=== EVALUATING MODEL 1 (BINARY) ===\n")
    model = load_model_with_fallback(model_m1_path)

    accuracies_m1 = []
    precisions_m1 = []
    recalls_m1 = []
    f1_scores_m1 = []

    for class_name in binary_classes_m1:
        class_folder = test_folder / "clasificacion_binaria" / class_name
        if class_folder.exists():
            images = load_images_from_folder(class_folder)
            if len(images) > 0:
                predictions = predict_batch(model, images, batch_size)
                true_labels = np.zeros(len(images), dtype=int) if class_name == "soya_sana" else np.ones(len(images), dtype=int)

                accuracy, precisions, recalls, f1s = calculate_metrics(true_labels, predictions)
                accuracies_m1.append(accuracy)
                precisions_m1.append(precisions[0] if class_name == "soya_sana" else precisions[1])
                recalls_m1.append(recalls[0] if class_name == "soya_sana" else recalls[1])
                f1_scores_m1.append(f1s[0] if class_name == "soya_sana" else f1s[1])

    write_excel(archivo_excel_salida_m1, binary_classes_m1, accuracies_m1, precisions_m1, recalls_m1, f1_scores_m1)
    print(f"M1 results saved to {archivo_excel_salida_m1}")

def evaluate_m2():
    print("\n=== EVALUATING MODEL 2 (PATHOGEN) ===\n")
    model = load_model_with_fallback(model_m2_path)

    accuracies_m2 = []
    precisions_m2 = []
    recalls_m2 = []
    f1_scores_m2 = []

    for idx, class_name in enumerate(disease_classes_m2):
        class_folder = test_folder / "clasificacion_patogeno" / class_name
        if class_folder.exists():
            images = load_images_from_folder(class_folder)
            if len(images) > 0:
                predictions = predict_batch(model, images, batch_size)
                true_labels = np.full(len(images), idx, dtype=int)

                accuracy, precisions, recalls, f1s = calculate_metrics(true_labels, predictions)
                accuracies_m2.append(accuracy)
                precisions_m2.append(precisions[idx])
                recalls_m2.append(recalls[idx])
                f1_scores_m2.append(f1s[idx])

    write_excel(archivo_excel_salida_m2, disease_classes_m2, accuracies_m2, precisions_m2, recalls_m2, f1_scores_m2)
    print(f"M2 results saved to {archivo_excel_salida_m2}")

def evaluate_models():
    print("=== MODEL EVALUATION ===")
    evaluate_m1()
    evaluate_m2()
    print("\nEvaluation complete!")

if __name__ == "__main__":
    evaluate_models()
