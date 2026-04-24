import json
from pathlib import Path
from typing import Any

def load_treatments(path: Path) -> dict[str, dict[str, Any]]:
    with path.open("r", encoding="utf-8") as f:
        data = json.load(f)
    
    if not isinstance(data, dict):
        raise ValueError("El archivo de tratamientos debe contener un objeto JSON.")
    
    return data
