from datetime import datetime

import config
import scanner


def main():
    print("=" * 70)
    print("ANALISIS PREVIO DE DATASET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("=" * 70)

    n_color = len(scanner.scan(config.SANA_COLOR_DIR))
    n_gray = len(scanner.scan(config.SANA_DIR / "Grayscale"))
    n_seg = len(scanner.scan(config.SANA_DIR / "Segmented"))

    print(f"\nSOYA SANA:")
    print(f"  Color/:      {n_color} (se usa)")
    print(f"  Grayscale/:  {n_gray} (se descarta)")
    print(f"  Segmented/:  {n_seg} (se descarta)")

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
    print(f"\n  Sana (Color): {n_color}")
    for group, n in totals.items():
        status = f"-> seleccionar {config.MAX_PER_CLASS}" if n >= config.MAX_PER_CLASS else f"-> deficit: {config.MAX_PER_CLASS - n}"
        print(f"    {group}: {n} {status}")
    print(f"\n  Minimo: {min(totals.values())} ({min(totals, key=totals.get)})")


if __name__ == "__main__":
    main()
