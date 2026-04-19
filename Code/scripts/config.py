from pathlib import Path

BASE_DIR = Path(r"D:\Datasets")
ENFERMA_DIR = BASE_DIR / "Soya_Enferma"
SANA_DIR = BASE_DIR / "Soya_Sana"
SANA_COLOR_DIR = SANA_DIR / "Color"          # PlantVillage (fondo controlado)
SANA_ASDID_DIR = SANA_DIR / "healthy"        # ASDID Healthy (campo real)
OUTPUT_DIR = BASE_DIR / "filtrado_calidad"
TM_DIR = BASE_DIR / "teachable_machine"

# Todas las fuentes de soya sana, en orden de prioridad
# El pipeline las recorre juntas con un hash compartido para evitar duplicados cross-fuente
SANA_SOURCES = [
    SANA_COLOR_DIR,   # PlantVillage
    SANA_ASDID_DIR,   # ASDID Healthy (campo real — mitiga domain shift)
]

MIN_RESOLUTION = 224
HASH_THRESHOLD = 3
RANDOM_SEED = 42
MAX_PER_CLASS = 1000
VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}

DISEASE_GROUPS = {
    "Bacterianas": [
        "Bacterial Blight",
        "Bacterial Pustule",
        "bacterial_blight",
        "6.Bacterial leaf Blight",
    ],
    "Fungicas": [
        "Brown Spot",
        "Frogeye Leaf Spot",
        "Target Leaf Spot",
        "septoria",
        "4.Septoria_Brown_Spot",
        "2.Vein Necrosis",
        "cercospora_leaf_blight",
        "frogeye",
        "target_spot",
        "powdery Mildew",
        "Sudden Death Syndrome",
        "downey_mildew",
        "Southern blight",
    ],
    "Roya": [
        "Rust",
        "ferrugen",
        "soybean_rust",
    ],
    "Virales": [
        "Yellow Mosaic",
        "Mossaic Virus",
        "Soyabean_Mosaic",
    ],
    "Plagas_Insectos": [
        "Caterpillar",
        "Diabrotica speciosa",
    ],
}

SOURCE_LABELS = {
    "Bacterial Blight": "Kaggle-sivm205",
    "Bacterial Pustule": "Kaggle-sivm205",
    "Brown Spot": "Kaggle-sivm205",
    "Frogeye Leaf Spot": "Kaggle-sivm205",
    "Target Leaf Spot": "Kaggle-sivm205",
    "Rust": "Kaggle-sivm205",
    "septoria": "Kaggle-sivm205",
    "powdery Mildew": "Kaggle-sivm205",
    "Sudden Death Syndrome": "Kaggle-sivm205",
    "Southern blight": "Kaggle-sivm205",
    "Caterpillar": "Kaggle-maeloisamignoni",
    "Diabrotica speciosa": "Kaggle-maeloisamignoni",
    "ferrugen": "Kaggle-vaishaligbhujade",
    "Yellow Mosaic": "Kaggle-vaishaligbhujade",
    "Mossaic Virus": "Kaggle-vaishaligbhujade",
    "bacterial_blight": "ASDID-Zenodo",
    "cercospora_leaf_blight": "ASDID-Zenodo",
    "frogeye": "ASDID-Zenodo",
    "target_spot": "ASDID-Zenodo",
    "soybean_rust": "ASDID-Zenodo",
    "downey_mildew": "ASDID-Zenodo",
    "Soyabean_Mosaic": "MH-SoyaHealthVision",
    "6.Bacterial leaf Blight": "India-Mendeley",
    "4.Septoria_Brown_Spot": "India-Mendeley",
    "2.Vein Necrosis": "India-Mendeley",
    # Fuentes sanas
    "Color": "PlantVillage",
    "healthy": "ASDID-Zenodo",
}
