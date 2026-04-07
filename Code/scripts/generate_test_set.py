import random
from pathlib import Path
from datetime import datetime

import config
import exporter


def _read_paths(filepath: Path) -> set[str]:
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
    print("GENERADOR DE SET DE PRUEBA (imagenes no seleccionadas)")
    print(f"Fecha: {timestamp}")
    print("=" * 70)

    test_dir = config.BASE_DIR / "test_set"
    tm_m2 = config.TM_DIR / "Modelo2_Tipo_Patogeno"

    selected_global = set()
    for group in config.DISEASE_GROUPS:
        traza = tm_m2 / f"{group}_trazabilidad.txt"
        selected_global.update(_read_paths(traza))

    sana_selected = set()
    tm_m1 = config.TM_DIR / "Modelo1_Sana_Enferma"
    sana_traza = config.OUTPUT_DIR / "sana_aprobadas.txt"
    all_sana = _read_paths(sana_traza)

    sana_dir = tm_m1 / "Soya_Sana"
    if sana_dir.exists():
        n_selected = len(list(sana_dir.glob("*.*")))
    else:
        n_selected = 0

    print(f"\n  SOYA SANA:")
    print(f"    Aprobadas: {len(all_sana)}, Seleccionadas para TM: {n_selected}")

    selected_sana_file = config.OUTPUT_DIR / "sana_aprobadas.txt"
    all_sana_paths = _read_paths(selected_sana_file)

    random.seed(config.RANDOM_SEED)
    sana_list = sorted(list(all_sana_paths))
    sana_used = set(random.sample(sana_list, min(config.MAX_PER_CLASS, len(sana_list))))

    sana_remaining = [Path(p) for p in all_sana_paths if p not in sana_used]
    if sana_remaining:
        random.seed(config.RANDOM_SEED + 100)
        sana_test = random.sample(sana_remaining, min(200, len(sana_remaining)))
        ok, _ = exporter.copy_images(sana_test, test_dir / "Soya_Sana", "test_sana")
        print(f"    Test set: {ok} copiadas")

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
            ok, _ = exporter.copy_images(test_sample, test_dir / group, f"test_{group[:4].lower()}")
            print(f"    {group}: {len(remaining)} restantes -> {ok} copiadas al test set")
        else:
            print(f"    {group}: sin imagenes restantes para test")

    print(f"\n  Test set guardado en: {test_dir}")
    print(f"  Usa estas imagenes para validar tu modelo en Teachable Machine")


if __name__ == "__main__":
    main()
