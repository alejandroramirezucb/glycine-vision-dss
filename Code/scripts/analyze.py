from datetime import datetime

import config
import scanner


def main():
    print("=" * 70)
    print("ANALISIS PREVIO DE DATASET")
    print(f"Fecha: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print(f"Presupuesto: {config.MAX_PER_CLASS} train + {config.TEST_PER_CLASS} test = "
          f"{config.MAX_PER_CLASS + config.TEST_PER_CLASS} por clase")
    print("=" * 70)

    # ── SOYA SANA ──────────────────────────────────────────────────────────
    print(f"\nSOYA SANA:")
    total_sana = 0
    for source_dir in config.SANA_SOURCES:
        n = len(scanner.scan(source_dir)) if source_dir.exists() else 0
        status = "(existe)" if source_dir.exists() else "(NO ENCONTRADA)"
        print(f"  {source_dir.name}/: {n} {status}")
        total_sana += n

    for subfolder in ["Grayscale", "Segmented"]:
        path = config.SANA_DIR / subfolder
        n = len(scanner.scan(path)) if path.exists() else 0
        print(f"  {subfolder}/: {n} (se descarta)")

    needed_sana = config.MAX_PER_CLASS + config.TEST_PER_CLASS
    sana_ok = total_sana >= needed_sana
    print(f"  -> Total: {total_sana} {'✓' if sana_ok else '⚠ DEFICIT'} "
          f"(necesitas {needed_sana})")

    # ── SOYA ENFERMA ────────────────────────────────────────────────────────
    print(f"\nSOYA ENFERMA POR GRUPO:")
    print("-" * 70)

    needed = config.MAX_PER_CLASS + config.TEST_PER_CLASS
    totals = {}

    for group, folders in config.DISEASE_GROUPS.items():
        group_total = 0
        details = []
        seen = set()
        for folder in folders:
            if folder in seen:
                continue
            seen.add(folder)
            path = config.ENFERMA_DIR / folder
            n = len(scanner.scan(path)) if path.exists() else 0
            exists = path.exists()
            if exists and n > 0:
                details.append(f"    {folder}: {n}")
            elif exists and n == 0:
                details.append(f"    {folder}: 0 (carpeta vacía)")
            # Si no existe, no se muestra (carpeta ausente es normal)
            group_total += n
        totals[group] = group_total

        if group_total >= needed:
            icon = "OK"
        elif group_total >= config.MAX_PER_CLASS:
            icon = "JUSTO"
        else:
            icon = "BAJO"

        print(f"\n  [{icon}] {group}: {group_total} / {needed} necesarios")
        for d in details:
            print(d)

    # Carpetas ignoradas documentadas
    print(f"\n  [IGNORADAS] carpetas en disco pero NO en config:")
    ignored = ["crestamento", "unused_cercospora_leaf_blight", "unused_soybean_rust"]
    for f in ignored:
        p = config.ENFERMA_DIR / f
        n = len(scanner.scan(p)) if p.exists() else 0
        if p.exists():
            print(f"    {f}: {n} (excluida intencionalmente)")

    print(f"\n{'=' * 70}")
    print("BALANCE")
    print(f"{'=' * 70}")
    print(f"\n  Sana: {total_sana} (necesitas {needed_sana})")
    for group, n in totals.items():
        deficit = needed - n
        if deficit <= 0:
            status = f"✓ sobran {-deficit} para dedup/filtrado"
        elif n >= config.MAX_PER_CLASS:
            avail_test = n - config.MAX_PER_CLASS
            status = f"~ solo {avail_test} imágenes de test disponibles (objetivo: {config.TEST_PER_CLASS})"
        else:
            status = f"✗ DEFICIT — faltan {config.MAX_PER_CLASS - n} para alcanzar train mínimo"
        print(f"  {group}: {n} {status}")

    min_group = min(totals, key=totals.get)
    avail_train = max(0, totals[min_group] - config.TEST_PER_CLASS)
    per_class = min(config.MAX_PER_CLASS, avail_train)
    print(f"\n  Grupo más limitado: {min_group} ({totals[min_group]} imágenes)")
    print(f"  -> El pipeline usará {per_class} imágenes de train por clase de enfermedad")


if __name__ == "__main__":
    main()
