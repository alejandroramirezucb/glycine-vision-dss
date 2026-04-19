from datetime import datetime

import config
import scanner


def main():
    print("=" * 70)
    print("ANALISIS PREVIO DE DATASET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    # ── SOYA SANA ──────────────────────────────────────────────────────────
    print(f"\nSOYA SANA:")
    total_sana = 0
    for source_dir in config.SANA_SOURCES:
        n = len(scanner.scan(source_dir)) if source_dir.exists() else 0
        status = "(existe)" if source_dir.exists() else "(NO ENCONTRADA)"
        print(f"  {source_dir.name}/: {n} {status}")
        total_sana += n

    # Carpetas descartadas de PlantVillage
    for subfolder in ["Grayscale", "Segmented"]:
        path = config.SANA_DIR / subfolder
        n = len(scanner.scan(path)) if path.exists() else 0
        print(f"  {subfolder}/: {n} (se descarta)")

    print(f"  -> Total sanas disponibles: {total_sana}")

    # ── SOYA ENFERMA ────────────────────────────────────────────────────────
    print(f"\nSOYA ENFERMA POR GRUPO:")
    print("-" * 70)

    totals = {}
    for group, folders in config.DISEASE_GROUPS.items():
        group_total = 0
        details = []
        for folder in folders:
            path = config.ENFERMA_DIR / folder
            n = len(scanner.scan(path)) if path.exists() else 0
            details.append(f"    {folder}: {n}")
            group_total += n
        totals[group] = group_total
        icon = "OK" if group_total >= config.MAX_PER_CLASS else "BAJO"
        print(f"\n  [{icon}] {group}: {group_total}")
        for d in details:
            print(d)

    print(f"\n{'=' * 70}")
    print("BALANCE")
    print(f"{'=' * 70}")
    print(f"\n  Sana (todas las fuentes): {total_sana}")
    for group, n in totals.items():
        if n >= config.MAX_PER_CLASS:
            status = f"-> seleccionar {config.MAX_PER_CLASS}"
        else:
            status = f"-> deficit: {config.MAX_PER_CLASS - n}"
        print(f"    {group}: {n} {status}")
    print(f"\n  Minimo enfermo: {min(totals.values())} ({min(totals, key=totals.get)})")


if __name__ == "__main__":
    main()
