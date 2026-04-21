import hashlib
import shutil
import random
from pathlib import Path
from PIL import Image
from config import (
    source_dataset_folder, test_folder, train_folder,
    test_images_per_class_max, train_images_per_class_max,
    image_min_resolution, image_required_channels, random_seed,
    disease_mapping, disease_classes_m2, binary_classes_m1
)

random.seed(random_seed)

def compute_md5(file_path):
    md5_hash = hashlib.md5()
    with open(file_path, "rb") as f:
        md5_hash.update(f.read())
    return md5_hash.hexdigest()

def validate_image(image_path):
    try:
        img = Image.open(image_path)
        return (img.width >= image_min_resolution and
                img.height >= image_min_resolution and
                img.mode == "RGB")
    except:
        return False

def load_source_images():
    images_by_class = {
        "soya_sana": [],
        "soya_enferma": [],
        "bacterianas": [], "fungicas": [], "plagas_insectos": [], "roya": [], "virales": []
    }

    soya_sana_dir = source_dataset_folder / "Soya_Sana"
    if soya_sana_dir.exists():
        for img_file in soya_sana_dir.rglob("*"):
            if img_file.is_file() and img_file.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                if validate_image(img_file):
                    images_by_class["soya_sana"].append(str(img_file))

    soya_enferma_dir = source_dataset_folder / "Soya_Enferma"
    if soya_enferma_dir.exists():
        for disease_dir in soya_enferma_dir.iterdir():
            if disease_dir.is_dir():
                target_class = None
                for key, value in disease_mapping.items():
                    if key.lower() in disease_dir.name.lower():
                        target_class = value
                        break

                if target_class and target_class in images_by_class:
                    for img_file in disease_dir.rglob("*"):
                        if img_file.is_file() and img_file.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                            if validate_image(img_file):
                                images_by_class[target_class].append(str(img_file))
                else:
                    for img_file in disease_dir.rglob("*"):
                        if img_file.is_file() and img_file.suffix.lower() in {".jpg", ".jpeg", ".png"}:
                            if validate_image(img_file):
                                images_by_class["soya_enferma"].append(str(img_file))

    return images_by_class

def remove_duplicates(images_by_class):
    seen_hashes = set()
    filtered_images = {k: [] for k in images_by_class}

    for class_name, image_list in images_by_class.items():
        for image_path in image_list:
            file_hash = compute_md5(image_path)
            if file_hash not in seen_hashes:
                seen_hashes.add(file_hash)
                filtered_images[class_name].append(image_path)

    return filtered_images

def calculate_quantities(images_by_class):
    class_counts = {k: len(v) for k, v in images_by_class.items()}

    test_per_class = min(test_images_per_class_max, min(class_counts.values()))
    train_per_class = min(train_images_per_class_max,
                         min(class_counts[k] - test_per_class for k in class_counts))

    return test_per_class, train_per_class

def copy_images_to_folder(images_by_class, output_folder, images_per_class, class_type):
    for class_name, image_list in images_by_class.items():
        if images_per_class > 0 and len(image_list) > 0:
            if class_type == "binaria":
                class_folder = output_folder / "clasificacion_binaria" / class_name
            else:
                class_folder = output_folder / "clasificacion_patogeno" / class_name

            class_folder.mkdir(parents=True, exist_ok=True)

            selected_images = random.sample(image_list, min(images_per_class, len(image_list)))
            for idx, image_path in enumerate(selected_images, 1):
                src_path = Path(image_path)
                ext = src_path.suffix
                dst_path = class_folder / f"{class_name}_{idx:04d}{ext}"
                shutil.copy2(src_path, dst_path)

def prepare_dataset():
    print("=== DATASET PREPARATION ===\n")

    print("Loading source images from D:\\Datasets\\Dataset...")
    images_by_class = load_source_images()

    print("Removing duplicates...")
    images_by_class = remove_duplicates(images_by_class)

    print("Calculating test and train quantities...")
    test_per_class, train_per_class = calculate_quantities(images_by_class)

    print(f"Test images per class: {test_per_class}")
    print(f"Train images per class: {train_per_class}\n")

    print("Copying test images to test folder...")
    copy_images_to_folder(images_by_class, test_folder, test_per_class, "binaria")
    copy_images_to_folder(images_by_class, test_folder, test_per_class, "patogeno")

    print("Copying train images to train folder...")
    copy_images_to_folder(images_by_class, train_folder, train_per_class, "binaria")
    copy_images_to_folder(images_by_class, train_folder, train_per_class, "patogeno")

    print("\nDataset preparation complete!")

if __name__ == "__main__":
    prepare_dataset()
