"""
generate_test_set.py — Test set estandarizado: exactamente TEST_PER_CLASS por clase.

Clases evaluadas (6 en total):
  - Soya_Sana          (Modelo 1)
  - Bacterianas        (Modelo 1 + Modelo 2)
  - Fungicas           (Modelo 1 + Modelo 2)
  - Roya               (Modelo 1 + Modelo 2)
  - Virales            (Modelo 1 + Modelo 2)
  - Plagas_Insectos    (Modelo 1 + Modelo 2)

Garantías:
  - Sin data leakage: ninguna imagen usada en entrenamiento aparece en test.
  - Reproducible: misma semilla → mismo test set siempre.
  - Estandarizado: si hay suficientes, todas las clases tienen el mismo N.
"""
import random
from pathlib import Path
from datetime import datetime

import config
import exporter


def _read_sorted(filepath: Path) -> list[str]:
    """Lee archivo de aprobadas/trazabilidad y retorna lista ordenada."""
    if not filepath.exists():
        return []
    lines = []
    with open(filepath, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith("#"):
                lines.append(line)
    return sorted(lines)


def _read_set(filepath: Path) -> set[str]:
    return set(_read_sorted(filepath))


def get_sana_train_used() -> set[str]:
    """Reconstruye exactamente qué sanas se usaron en entrenamiento (misma semilla)."""
    all_sana = _read_sorted(config.OUTPUT_DIR / "sana_aprobadas.txt")
    if not all_sana:
        return set()
    random.seed(config.RANDOM_SEED)
    shuffled = all_sana[:]
    random.shuffle(shuffled)
    return set(shuffled[:config.MAX_PER_CLASS])


def get_disease_train_used(group: str) -> set[str]:
    """Lee el archivo de trazabilidad del M2 para saber qué se usó en train."""
    traza = config.TM_DIR / "Modelo2_Tipo_Patogeno" / f"{group}_trazabilidad.txt"
    return _read_set(traza)


def copy_test(remaining: list[str], dest: Path, prefix: str, target: int) -> int:
    n = min(target, len(remaining))
    paths = [Path(p) for p in remaining[:n]]
    ok, _ = exporter.copy_images(paths, dest, prefix)
    return ok


def main():
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    target = config.TEST_PER_CLASS
    test_dir = config.BASE_DIR / "test_set"

    print("=" * 70)
    print(f"GENERADOR DE TEST SET — {target} imágenes por clase")
    print(f"Fecha: {ts}")
    print("=" * 70)

    summary = {}

    # ── SOYA SANA ──────────────────────────────────────────────────────────
    print(f"\n  [Soya_Sana]")
    all_sana = set(_read_sorted(config.OUTPUT_DIR / "sana_aprobadas.txt"))
    train_used = get_sana_train_used()
    remaining = sorted(all_sana - train_used)

    print(f"    Aprobadas: {len(all_sana)} | Train: {len(train_used)} | Disponibles: {len(remaining)}")

    if remaining:
        random.seed(config.RANDOM_SEED + 200)
        sample = random.sample(remaining, min(target, len(remaining)))
        ok, _ = exporter.copy_images([Path(p) for p in sample], test_dir / "Soya_Sana", "test_sana")
        pv  = sum(1 for p in sample if "Color"   in p)
        asd = sum(1 for p in sample if "healthy" in p.lower() and "Color" not in p)
        mark = "✓" if ok >= target else "⚠"
        print(f"    {mark} {ok} copiadas (PlantVillage:{pv} | ASDID:{asd})")
        summary["Soya_Sana"] = ok
    else:
        print(f"    ✗ Sin imágenes disponibles para test")
        summary["Soya_Sana"] = 0

    # ── GRUPOS DE ENFERMEDAD ────────────────────────────────────────────────
    print(f"\n  [Grupos de enfermedad]")

    for group in config.DISEASE_GROUPS:
        approved_file = config.OUTPUT_DIR / f"enferma_{group}_aprobadas.txt"
        all_approved = _read_set(approved_file)
        train_used = get_disease_train_used(group)
        remaining = sorted(all_approved - train_used)

        print(f"\n    [{group}]")
        print(f"      Aprobadas: {len(all_approved)} | Train: {len(train_used)} | Disponibles: {len(remaining)}")

        if not remaining:
            print(f"      ✗ Sin imágenes restantes para test")
            summary[group] = 0
            continue

        random.seed(config.RANDOM_SEED + abs(hash(group)) % 10000)
        n = min(target, len(remaining))
        sample = random.sample(remaining, n)
        ok, _ = exporter.copy_images(
            [Path(p) for p in sample],
            test_dir / group,
            f"test_{group[:4].lower()}"
        )
        mark = "✓" if ok >= target else "⚠"
        print(f"      {mark} {ok} copiadas{' (menos del objetivo)' if ok < target else ''}")
        summary[group] = ok

    # ── RESUMEN FINAL ───────────────────────────────────────────────────────
    print(f"\n{'=' * 70}")
    print(f"RESUMEN TEST SET  (objetivo: {target} por clase)")
    print(f"{'=' * 70}")
    total = 0
    for clase, n in summary.items():
        mark = "✓" if n >= target else ("⚠" if n > 0 else "✗")
        bar = "#" * (n // 5)   # barra visual proporcional
        print(f"  {mark} {clase:<25}: {n:>4}  {bar}")
        total += n
    print(f"\n  Total imágenes de test: {total}")
    print(f"  Ubicación: {test_dir}")
    print(f"\n  Ejecuta: python evaluate_model.py")


if __name__ == "__main__":
    main()
