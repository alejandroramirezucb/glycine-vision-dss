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
    # Se recorren TODAS las fuentes sanas con un hash compartido.
    # Así el deduplicador elimina copias exactas/casi-exactas entre fuentes
    # (ej. la misma hoja que aparece en PlantVillage y en ASDID).
    print("\n  SOYA SANA (múltiples fuentes — hash compartido):")
    sana_hashes = {}
    sana_approved = []

    for source_dir in config.SANA_SOURCES:
        if not source_dir.exists():
            print(f"      {source_dir.name}: NO ENCONTRADA (revisar ruta en config.py)")
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

        for folder in folders:
            path = config.ENFERMA_DIR / folder
            if not path.exists():
                print(f"      {folder}: NO ENCONTRADA")
                continue
            images = scanner.scan(path)
            approved, stats = quality_filter.apply(images, group_hashes)
            group_approved[group].extend(approved)
            group_by_source[group][folder] = approved
            _print_stats(folder, stats)

        total = len(group_approved[group])
        icon = "OK" if total >= config.MAX_PER_CLASS else "BAJO"
        print(f"    -> Total: {total} [{icon}]")

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
    all_diseased = sum(len(a) for a in group_approved.values())
    print(f"  Enferma: {all_diseased}")
    print(f"\n  Por grupo:")
    for g, a in group_approved.items():
        print(f"    {g}: {len(a)}")

    min_available = min(len(a) for a in group_approved.values())
    per_class = min(config.MAX_PER_CLASS, min_available)
    print(f"\n  Balance Modelo 2: {per_class} imagenes por clase de enfermedad")
    return per_class


def run_selection(sana_approved, group_approved, per_class):
    print(f"\n PASO 3: SELECCION FINAL")
    print("-" * 50)

    config.TM_DIR.mkdir(parents=True, exist_ok=True)
    m1_dir = config.TM_DIR / "Modelo1_Sana_Enferma"
    m2_dir = config.TM_DIR / "Modelo2_Tipo_Patogeno"

    # ── MODELO 1: Sana vs Enferma ──────────────────────────────────────────
    # Las 1000 sanas ahora vienen mezcladas de PlantVillage + ASDID-Healthy,
    # lo que reduce el domain shift respecto a las imágenes de campo enfermas.
    print("\n  MODELO 1: Sana vs Enferma")
    random.seed(config.RANDOM_SEED)
    sana_sel = random.sample(sana_approved, min(config.MAX_PER_CLASS, len(sana_approved)))
    ok, _ = exporter.copy_images(sana_sel, m1_dir / "Soya_Sana", "sana")
    print(f"    Sana: {ok} copiadas")

    # Contar cuántas vienen de cada fuente (informativo)
    pv_count = sum(1 for p in sana_sel if "Color" in str(p))
    asdid_count = sum(1 for p in sana_sel if "healthy" in str(p).lower() and "Color" not in str(p))
    print(f"      PlantVillage (Color/):  {pv_count}")
    print(f"      ASDID (healthy/):       {asdid_count}")

    all_diseased = [p for paths in group_approved.values() for p in paths]
    random.seed(config.RANDOM_SEED + 1)
    enf_sel = random.sample(all_diseased, min(config.MAX_PER_CLASS, len(all_diseased)))
    ok, _ = exporter.copy_images(enf_sel, m1_dir / "Soya_Enferma", "enf")
    print(f"    Enferma: {ok} copiadas")

    # ── MODELO 2: Tipo de Patógeno ─────────────────────────────────────────
    print("\n  MODELO 2: Tipo de Patogeno (5 clases)")
    for group, folders in config.DISEASE_GROUPS.items():
        paths = group_approved[group]
        by_source = sampler.classify_by_source(paths, folders)
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
    print(f"    Soya_Sana/     -> clase 'Soya_Sana'  (mix PlantVillage + ASDID-Healthy)")
    print(f"    Soya_Enferma/  -> clase 'Soya_Enferma'")
    print(f"\n  Modelo 2: {m2}")
    for g in config.DISEASE_GROUPS:
        d = m2 / g
        # -1 para no contar el .txt de trazabilidad
        files = [f for f in d.glob("*.*") if f.suffix.lower() in config.VALID_EXTENSIONS] if d.exists() else []
        print(f"    {g}/ ({len(files)} imagenes)")


def _print_stats(name, stats):
    pct = (stats.approved / stats.total * 100) if stats.total > 0 else 0
    print(f"      {name}: {stats.total} -> "
          f"ilegible:{stats.unreadable} res:{stats.low_resolution} "
          f"gris:{stats.grayscale} dup:{stats.duplicate} "
          f"-> {stats.approved} ({pct:.0f}%)")


def main():
    timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    print("=" * 70)
    print("PIPELINE - Seleccion para Teachable Machine")
    print(f"Fecha: {timestamp}")
    print(f"Filtros: res>={config.MIN_RESOLUTION}px, pHash<={config.HASH_THRESHOLD}, color")
    print(f"Clases enfermas: 5 | Semilla: {config.RANDOM_SEED} | Max/clase: {config.MAX_PER_CLASS}")
    print(f"Fuentes sanas: {[str(s.name) for s in config.SANA_SOURCES]}")
    print("=" * 70)

    sana_approved, group_approved, _ = run_quality_filter()
    per_class = run_summary(sana_approved, group_approved)
    run_selection(sana_approved, group_approved, per_class)
    print_result()


if __name__ == "__main__":
    main()
