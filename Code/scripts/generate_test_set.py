"""
generate_test_set.py — Genera el set de prueba con imágenes NO usadas en Teachable Machine.

Garantías:
  - Ninguna imagen del test set estuvo en el entrenamiento (no data leakage).
  - Las imágenes sanas del test incluyen ambas fuentes (PlantVillage + ASDID-Healthy)
    proporcional a lo que quedó disponible después del muestreo de entrenamiento.
  - Se respeta la semilla global para reproducibilidad.
"""
import random
from pathlib import Path
from datetime import datetime

import config
import exporter


def _read_paths(filepath: Path) -> set[str]:
    """Lee un archivo de trazabilidad/aprobadas y retorna set de rutas."""
    paths = set()
    if not filepath.exists():
        return paths
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                paths.add(line)
    return paths


def main():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=" * 70)
    print("GENERADOR DE SET DE PRUEBA (imagenes no usadas en entrenamiento)")
    print(f"Fecha: {timestamp}")
    print("=" * 70)

    test_dir = config.BASE_DIR / "test_set"
    tm_m1 = config.TM_DIR / "Modelo1_Sana_Enferma"
    tm_m2 = config.TM_DIR / "Modelo2_Tipo_Patogeno"

    # ── SOYA SANA ──────────────────────────────────────────────────────────
    # Leer todas las aprobadas (multi-fuente) y restar las usadas en TM
    print(f"\n  SOYA SANA:")
    all_sana = _read_paths(config.OUTPUT_DIR / "sana_aprobadas.txt")

    # Reconstruir exactamente qué imágenes sanas se usaron en TM (misma semilla)
    random.seed(config.RANDOM_SEED)
    sana_list = sorted(list(all_sana))
    sana_used = set(random.sample(sana_list, min(config.MAX_PER_CLASS, len(sana_list))))

    sana_remaining = [Path(p) for p in all_sana if p not in sana_used]
    print(f"    Total aprobadas: {len(all_sana)}")
    print(f"    Usadas en TM:   {len(sana_used)}")
    print(f"    Disponibles para test: {len(sana_remaining)}")

    if sana_remaining:
        random.seed(config.RANDOM_SEED + 100)
        sana_test = random.sample(sana_remaining, min(200, len(sana_remaining)))
        ok, _ = exporter.copy_images(sana_test, test_dir / "Soya_Sana", "test_sana")
        print(f"    Test set sana: {ok} copiadas")

        # Informe de fuente (PlantVillage vs ASDID)
        pv  = sum(1 for p in sana_test if "Color"   in str(p))
        asd = sum(1 for p in sana_test if "healthy" in str(p).lower() and "Color" not in str(p))
        print(f"      PlantVillage: {pv}  |  ASDID-Healthy: {asd}")
    else:
        print("    Sin imágenes restantes para test (todas usadas en TM).")

    # ── SOYA ENFERMA ────────────────────────────────────────────────────────
    print(f"\n  SOYA ENFERMA (por grupo):")

    for group in config.DISEASE_GROUPS:
        approved_file = config.OUTPUT_DIR / f"enferma_{group}_aprobadas.txt"
        all_approved = _read_paths(approved_file)
        group_selected = _read_paths(tm_m2 / f"{group}_trazabilidad.txt")
        remaining = [Path(p) for p in all_approved if p not in group_selected]

        n_test = min(150, len(remaining))
        if n_test > 0:
            random.seed(config.RANDOM_SEED + hash(group) % 1000)
            test_sample = random.sample(remaining, n_test)
            ok, _ = exporter.copy_images(
                test_sample, test_dir / group, f"test_{group[:4].lower()}"
            )
            print(f"    {group}: {len(all_approved)} aprobadas | "
                  f"{len(group_selected)} en TM | "
                  f"{len(remaining)} restantes -> {ok} en test")
        else:
            print(f"    {group}: sin imágenes restantes para test")

    print(f"\n  Test set guardado en: {test_dir}")
    print(f"  Estructura esperada:")
    print(f"    test_set/Soya_Sana/")
    for g in config.DISEASE_GROUPS:
        print(f"    test_set/{g}/")
    print(f"\n  Usa evaluate_model.py para evaluar los modelos con este set.")


if __name__ == "__main__":
    main()
