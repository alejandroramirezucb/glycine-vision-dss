import random
from datetime import datetime

import config
import scanner
import quality_filter
import sampler
import exporter


def run_quality_filter():
    print("\n PASO 1: FILTRADO DE CALIDAD")
    print("-" * 50)

    # ── SOYA SANA ──────────────────────────────────────────────────────────
    print("\n  SOYA SANA (múltiples fuentes — hash compartido):")
    sana_hashes = {}
    sana_approved = []

    for source_dir in config.SANA_SOURCES:
        if not source_dir.exists():
            print(f"      {source_dir.name}: NO ENCONTRADA")
            continue
        images = scanner.scan(source_dir)
        approved, stats = quality_filter.apply(images, sana_hashes)
        sana_approved.extend(approved)
        _print_stats(source_dir.name, stats)

    print(f"    -> Total sanas aprobadas: {len(sana_approved)}")
    config.OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    exporter.write_approved_list(
        sana_approved,
        config.OUTPUT_DIR / "sana_aprobadas.txt",
        "Soya sana aprobadas (multi-fuente)",
    )

    # ── SOYA ENFERMA ────────────────────────────────────────────────────────
    print("\n  SOYA ENFERMA:")
    group_approved = {}
    group_by_source = {}

    for group, folders in config.DISEASE_GROUPS.items():
        print(f"\n    {group}:")
        group_approved[group] = []
        group_by_source[group] = {}
        group_hashes = {}

        seen_folders = set()
        for folder in folders:
            if folder in seen_folders:
                continue
            seen_folders.add(folder)

            path = config.ENFERMA_DIR / folder
            if not path.exists():
                continue   # silencioso — carpeta no descargada aún

            images = scanner.scan(path)
            if not images:
                continue

            approved, stats = quality_filter.apply(images, group_hashes)
            group_approved[group].extend(approved)
            group_by_source[group][folder] = approved
            _print_stats(folder, stats)

        total = len(group_approved[group])
        needed = config.MAX_PER_CLASS + config.TEST_PER_CLASS
        if total >= needed:
            icon = "OK"
        elif total >= config.MAX_PER_CLASS:
            icon = "JUSTO"
        else:
            icon = "BAJO"
        print(f"    -> Total aprobadas: {total} [{icon}] "
              f"(necesitas {needed} = {config.MAX_PER_CLASS} train + {config.TEST_PER_CLASS} test)")

        exporter.write_approved_list(
            group_approved[group],
            config.OUTPUT_DIR / f"enferma_{group}_aprobadas.txt",
            f"{group} aprobadas",
        )

    all_diseased = [p for paths in group_approved.values() for p in paths]
    exporter.write_approved_list(
        all_diseased,
        config.OUTPUT_DIR / "enferma_todas_aprobadas.txt",
        "Todas enfermas",
    )

    return sana_approved, group_approved, group_by_source


def run_summary(sana_approved, group_approved):
    print(f"\n PASO 2: RESUMEN")
    print("-" * 50)
    print(f"  Sana:    {len(sana_approved)}")
    print(f"  Enferma: {sum(len(a) for a in group_approved.values())}")

    needed = config.MAX_PER_CLASS + config.TEST_PER_CLASS
    print(f"\n  Por grupo (objetivo: {needed} por clase):")
    for g, a in group_approved.items():
        n = len(a)
        if n >= needed:
            st = "✓"
        elif n >= config.MAX_PER_CLASS:
            st = "~ (test limitado)"
        else:
            st = "✗ DEFICIT"
        print(f"    {g}: {n} {st}")

    # El per_class de M2 = mínimo disponible para train (restando test reservado)
    available_for_train = {g: max(0, len(a) - config.TEST_PER_CLASS)
                           for g, a in group_approved.items()}
    min_train = min(available_for_train.values())
    per_class = min(config.MAX_PER_CLASS, min_train)
    print(f"\n  Imágenes de entrenamiento por clase (M2): {per_class}")
    return per_class


def run_selection(sana_approved, group_approved, per_class):
    print(f"\n PASO 3: SELECCION FINAL")
    print("-" * 50)

    config.TM_DIR.mkdir(parents=True, exist_ok=True)
    m1_dir = config.TM_DIR / "Modelo1_Sana_Enferma"
    m2_dir = config.TM_DIR / "Modelo2_Tipo_Patogeno"

    # ── MODELO 1 ───────────────────────────────────────────────────────────
    print("\n  MODELO 1: Sana vs Enferma")
    random.seed(config.RANDOM_SEED)
    sana_shuffled = sana_approved[:]
    random.shuffle(sana_shuffled)
    sana_train_sel = sana_shuffled[:config.MAX_PER_CLASS]

    ok, _ = exporter.copy_images(sana_train_sel, m1_dir / "Soya_Sana", "sana")
    print(f"    Sana: {ok} para entrenamiento")
    pv  = sum(1 for p in sana_train_sel if "Color"   in str(p))
    asd = sum(1 for p in sana_train_sel if "healthy" in str(p).lower() and "Color" not in str(p))
    print(f"      PlantVillage: {pv}  |  ASDID-Healthy: {asd}")

    all_diseased = [p for paths in group_approved.values() for p in paths]
    random.seed(config.RANDOM_SEED + 1)
    enf_sel = random.sample(all_diseased, min(config.MAX_PER_CLASS, len(all_diseased)))
    ok, _ = exporter.copy_images(enf_sel, m1_dir / "Soya_Enferma", "enf")
    print(f"    Enferma: {ok} para entrenamiento")

    # ── MODELO 2 ───────────────────────────────────────────────────────────
    print("\n  MODELO 2: Tipo de Patogeno (5 clases)")
    for group, folders in config.DISEASE_GROUPS.items():
        paths = group_approved[group]
        unique_folders = list(dict.fromkeys(folders))
        by_source = sampler.classify_by_source(paths, unique_folders)
        selected, breakdown = sampler.sample(by_source, per_class)
        ok, _ = exporter.copy_images(selected, m2_dir / group, group[:4].lower())
        exporter.write_traceability(group, selected, breakdown, m2_dir)
        print(f"    {group}: {ok} copiadas")
        for src, n in sorted(breakdown.items()):
            label = config.SOURCE_LABELS.get(src, "?")
            available = len(by_source.get(src, []))
            pct = (n / len(selected) * 100) if selected else 0
            print(f"      {src} ({label}): {n}/{available} ({pct:.0f}%)")


def print_result():
    print(f"\n{'=' * 70}")
    print("RESULTADO FINAL")
    print(f"{'=' * 70}")
    m1 = config.TM_DIR / "Modelo1_Sana_Enferma"
    m2 = config.TM_DIR / "Modelo2_Tipo_Patogeno"
    print(f"\n  Modelo 1: {m1}")
    print(f"    Soya_Sana/    -> 'healthy'   (PlantVillage + ASDID campo real)")
    print(f"    Soya_Enferma/ -> 'diseased'")
    print(f"\n  Modelo 2: {m2}")
    for g in config.DISEASE_GROUPS:
        d = m2 / g
        files = [f for f in d.glob("*.*")
                 if f.suffix.lower() in config.VALID_EXTENSIONS] if d.exists() else []
        print(f"    {g}/ ({len(files)} imágenes de entrenamiento)")
    print(f"\n  Ejecuta generate_test_set.py → {config.TEST_PER_CLASS} imágenes de test/clase")


def _print_stats(name, stats):
    pct = (stats.approved / stats.total * 100) if stats.total > 0 else 0
    print(f"      {name}: {stats.total} -> "
          f"ilegible:{stats.unreadable} res:{stats.low_resolution} "
          f"gris:{stats.grayscale} dup:{stats.duplicate} "
          f"-> {stats.approved} ({pct:.0f}%)")


def main():
    ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=" * 70)
    print("PIPELINE - Seleccion para Teachable Machine")
    print(f"Fecha: {ts}")
    print(f"Filtros: res>={config.MIN_RESOLUTION}px, pHash<={config.HASH_THRESHOLD}, color")
    print(f"Train/clase: {config.MAX_PER_CLASS} | Test/clase: {config.TEST_PER_CLASS} | Semilla: {config.RANDOM_SEED}")
    print(f"Fuentes sanas: {[s.name for s in config.SANA_SOURCES]}")
    print("=" * 70)

    sana_approved, group_approved, _ = run_quality_filter()
    per_class = run_summary(sana_approved, group_approved)
    run_selection(sana_approved, group_approved, per_class)
    print_result()


if __name__ == "__main__":
    main()
