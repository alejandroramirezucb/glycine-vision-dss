"""Valida los notebooks de entrenamiento antes de integrarlos.

Comprueba que cada archivo sea JSON válido, que todas las celdas de código
tengan sintaxis Python correcta y que no queden comentarios en el código
(la convención del proyecto es explicar en celdas markdown).
"""

from __future__ import annotations

import ast
import json
import sys
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
NOTEBOOKS = RAIZ / "training" / "notebooks"


def _codigo(celda: dict) -> str:
    return "".join(celda.get("source", []))


def validar(ruta: Path) -> list[str]:
    errores: list[str] = []
    try:
        notebook = json.loads(ruta.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        return [f"JSON inválido: {exc}"]

    celdas = notebook.get("cells", [])
    if not celdas:
        errores.append("no contiene celdas")

    for indice, celda in enumerate(celdas):
        if celda.get("cell_type") != "code":
            continue
        fuente = _codigo(celda)
        if fuente.lstrip().startswith(("!", "%")):
            continue
        try:
            ast.parse(fuente)
        except SyntaxError as exc:
            errores.append(f"celda {indice}: sintaxis inválida en la línea {exc.lineno}")
        for numero, linea in enumerate(fuente.splitlines(), start=1):
            if linea.lstrip().startswith("#"):
                errores.append(f"celda {indice}, línea {numero}: comentario en el código")

    return errores


def main() -> int:
    rutas = sorted(NOTEBOOKS.glob("*.ipynb"))
    if not rutas:
        print(f"No se encontraron notebooks en {NOTEBOOKS}", file=sys.stderr)
        return 1

    fallidos = 0
    for ruta in rutas:
        errores = validar(ruta)
        if errores:
            fallidos += 1
            print(f"FALLA  {ruta.relative_to(RAIZ)}")
            for error in errores:
                print(f"       {error}")
        else:
            print(f"OK     {ruta.relative_to(RAIZ)}")

    print(f"\n{len(rutas) - fallidos}/{len(rutas)} notebooks válidos")
    return 1 if fallidos else 0


if __name__ == "__main__":
    raise SystemExit(main())
