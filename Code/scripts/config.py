from pathlib import Path

BASE_DIR = Path(r"D:\Datasets")
ENFERMA_DIR = BASE_DIR / "Soya_Enferma"
SANA_DIR = BASE_DIR / "Soya_Sana"
SANA_COLOR_DIR = SANA_DIR / "Color"       # PlantVillage (fondo controlado)
SANA_ASDID_DIR = SANA_DIR / "healthy"     # ASDID Healthy (campo real)
OUTPUT_DIR = BASE_DIR / "filtrado_calidad"
TM_DIR = BASE_DIR / "teachable_machine"

SANA_SOURCES = [
    SANA_COLOR_DIR,
    SANA_ASDID_DIR,
]

MIN_RESOLUTION = 224
HASH_THRESHOLD = 3
RANDOM_SEED = 42
MAX_PER_CLASS = 800   # imágenes de entrenamiento por clase
TEST_PER_CLASS = 100  # imágenes de test FIJAS por clase (comparables)
VALID_EXTENSIONS = {".jpg", ".jpeg", ".png", ".bmp", ".tiff", ".tif", ".webp"}

# ── NOMENCLATURA DE SUFIJOS ───────────────────────────────────────────────────
# Sin sufijo  = fuentes originales (sivm205, ASDID, India-Mendeley, etc.)
# Sufijo "4"  = mamun009 (Kaggle) — 14 clases
# Sufijo "3"  = tercer dataset adicional
# "crestamento" se EXCLUYE — no es enfermedad clasificable
# "unused_*"  se EXCLUYE — imágenes descartadas por ASDID
# ─────────────────────────────────────────────────────────────────────────────

DISEASE_GROUPS = {
    "Bacterianas": [
        # ── Originales ──────────────────────────────────────────────────────
        "Bacterial Blight",          # Kaggle-sivm205
        "Bacterial Pustule",         # Kaggle-sivm205
        "bacterial_blight",          # ASDID-Zenodo
        "6.Bacterial leaf Blight",   # India-Mendeley
        # ── mamun009 (sufijo 4) ─────────────────────────────────────────────
        "Bacterial Pustule4",        # Kaggle-mamun009
        # ── Dataset 3 (sufijo 3) ────────────────────────────────────────────
        "Bacterial Pustule 3",       # Dataset-3
    ],
    "Fungicas": [
        # ── Originales ──────────────────────────────────────────────────────
        "Brown Spot",                # Kaggle-sivm205
        "Frogeye Leaf Spot",         # Kaggle-sivm205
        "Target Leaf Spot",          # Kaggle-sivm205
        "septoria",                  # Kaggle-sivm205
        "4.Septoria_Brown_Spot",     # India-Mendeley
        "2.Vein Necrosis",           # India-Mendeley
        "cercospora_leaf_blight",    # ASDID-Zenodo
        "frogeye",                   # ASDID-Zenodo
        "target_spot",               # ASDID-Zenodo
        "powdery Mildew",            # Kaggle-sivm205
        "Sudden Death Syndrome",     # Kaggle-sivm205
        "downey_mildew",             # ASDID-Zenodo
        "Southern blight",           # Kaggle-sivm205
        # ── mamun009 (sufijo 4) ─────────────────────────────────────────────
        "brown_spot4",               # Kaggle-mamun009
        "Frogeye Leaf Spot4",        # Kaggle-mamun009
        "powdery_mildew4",           # Kaggle-mamun009
        "septoria4",                 # Kaggle-mamun009
        "Southern blight4",          # Kaggle-mamun009
        "Sudden Death Syndrome4",    # Kaggle-mamun009
        "Target Leaf Spot4",         # Kaggle-mamun009
        # ── Dataset 3 (sufijo 3) ────────────────────────────────────────────
        "brown_spot3",               # Dataset-3
        "Frogeye Leaf Spot3",        # Dataset-3
        "powdery_mildew3",           # Dataset-3
        "septoria3",                 # Dataset-3
        "Southern blight3",          # Dataset-3
        "Sudden Death Syndrome3",    # Dataset-3
        "Target Leaf Spot3",         # Dataset-3
    ],
    "Roya": [
        # ── Originales ──────────────────────────────────────────────────────
        "Rust",                      # Kaggle-sivm205
        "ferrugen",                  # Kaggle-vaishaligbhujade
        "soybean_rust",              # ASDID-Zenodo
        # ── mamun009 (sufijo 4) ─────────────────────────────────────────────
        "Rust4",                     # Kaggle-mamun009
        "ferrugen4",                 # Kaggle-mamun009
        # ── Dataset 3 (sufijo 3) ────────────────────────────────────────────
        "Rust3",                     # Dataset-3
        "ferrugen3",                 # Dataset-3
    ],
    "Virales": [
        # ── Originales ──────────────────────────────────────────────────────
        "Yellow Mosaic",             # Kaggle-vaishaligbhujade
        "Mossaic Virus",             # Kaggle-vaishaligbhujade
        "Soyabean_Mosaic",           # MH-SoyaHealthVision
        # ── mamun009 (sufijo 4) — MÁS IMPORTANTES para cubrir déficit ───────
        "Mossaic Virus4",            # Kaggle-mamun009
        "Yellow Mosaic4",            # Kaggle-mamun009
        # ── Dataset 3 (sufijo 3) ────────────────────────────────────────────
        "Mossaic Virus3",            # Dataset-3
        "Yellow Mosaic3",            # Dataset-3
    ],
    "Plagas_Insectos": [
        # ── Originales ──────────────────────────────────────────────────────
        "Caterpillar",               # Kaggle-maeloisamignoni
        "Diabrotica speciosa",       # Kaggle-maeloisamignoni
        # mamun009 y dataset-3 no aportan nuevas carpetas de plagas
    ],
}

# Carpetas que existen en disco pero NO se usan (documentadas aquí):
# - "crestamento"                  → no es enfermedad de soya clasificable
# - "unused_cercospora_leaf_blight" → imágenes descartadas por ASDID (calidad baja)
# - "unused_soybean_rust"          → imágenes descartadas por ASDID (calidad baja)

SOURCE_LABELS = {
    # sivm205
    "Bacterial Blight":       "Kaggle-sivm205",
    "Bacterial Pustule":      "Kaggle-sivm205",
    "Brown Spot":             "Kaggle-sivm205",
    "Frogeye Leaf Spot":      "Kaggle-sivm205",
    "Target Leaf Spot":       "Kaggle-sivm205",
    "Rust":                   "Kaggle-sivm205",
    "septoria":               "Kaggle-sivm205",
    "powdery Mildew":         "Kaggle-sivm205",
    "Sudden Death Syndrome":  "Kaggle-sivm205",
    "Southern blight":        "Kaggle-sivm205",
    # maeloisamignoni
    "Caterpillar":            "Kaggle-maeloisamignoni",
    "Diabrotica speciosa":    "Kaggle-maeloisamignoni",
    # vaishaligbhujade
    "ferrugen":               "Kaggle-vaishaligbhujade",
    "Yellow Mosaic":          "Kaggle-vaishaligbhujade",
    "Mossaic Virus":          "Kaggle-vaishaligbhujade",
    # ASDID-Zenodo
    "bacterial_blight":       "ASDID-Zenodo",
    "cercospora_leaf_blight": "ASDID-Zenodo",
    "frogeye":                "ASDID-Zenodo",
    "target_spot":            "ASDID-Zenodo",
    "soybean_rust":           "ASDID-Zenodo",
    "downey_mildew":          "ASDID-Zenodo",
    # MH-SoyaHealthVision
    "Soyabean_Mosaic":        "MH-SoyaHealthVision",
    # India-Mendeley
    "6.Bacterial leaf Blight":"India-Mendeley",
    "4.Septoria_Brown_Spot":  "India-Mendeley",
    "2.Vein Necrosis":        "India-Mendeley",
    # mamun009 (sufijo 4)
    "Bacterial Pustule4":     "Kaggle-mamun009",
    "brown_spot4":            "Kaggle-mamun009",
    "Frogeye Leaf Spot4":     "Kaggle-mamun009",
    "powdery_mildew4":        "Kaggle-mamun009",
    "Rust4":                  "Kaggle-mamun009",
    "ferrugen4":              "Kaggle-mamun009",
    "septoria4":              "Kaggle-mamun009",
    "Southern blight4":       "Kaggle-mamun009",
    "Sudden Death Syndrome4": "Kaggle-mamun009",
    "Target Leaf Spot4":      "Kaggle-mamun009",
    "Yellow Mosaic4":         "Kaggle-mamun009",
    "Mossaic Virus4":         "Kaggle-mamun009",
    # Dataset-3 (sufijo 3)
    "Bacterial Pustule 3":    "Dataset-3",
    "brown_spot3":            "Dataset-3",
    "Frogeye Leaf Spot3":     "Dataset-3",
    "powdery_mildew3":        "Dataset-3",
    "Rust3":                  "Dataset-3",
    "ferrugen3":              "Dataset-3",
    "septoria3":              "Dataset-3",
    "Southern blight3":       "Dataset-3",
    "Sudden Death Syndrome3": "Dataset-3",
    "Target Leaf Spot3":      "Dataset-3",
    "Yellow Mosaic3":         "Dataset-3",
    "Mossaic Virus3":         "Dataset-3",
    # Sanas
    "Color":                  "PlantVillage",
    "healthy":                "ASDID-Zenodo",
}
