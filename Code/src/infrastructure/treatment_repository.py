import json
from pathlib import Path
from domain.treatment import TreatmentInfo

_LABEL_MAP: dict[str, str] = {
    "bacterial_diseases": "Bacterianas",
    "fungal_diseases":    "Fungicas",
    "rust_disease":       "Roya",
    "viral_diseases":     "Virales",
    "insect_pests":       "Plagas_Insectos",
}

_JSON_PATH = Path(__file__).resolve().parents[2] / "tratamientos.json"

class JsonTreatmentRepository:
    def __init__(self, path: Path = _JSON_PATH) -> None:
        if not path.exists():
            raise FileNotFoundError(f"tratamientos.json no encontrado: {path}")
        with path.open(encoding="utf-8") as f:
            self._data: dict = json.load(f)

    def get_by_label(self, label: str) -> TreatmentInfo | None:
        key = _LABEL_MAP.get(label.strip().lower().replace(" ", "_"))
        
        if not key or key not in self._data:
            return None
        
        d = self._data[key]
        t = d["tratamiento"]
        
        return TreatmentInfo(
            disease_key=key,
            nombre_es=d["nombre_es"],
            patogenos=d["patogenos"],
            sintomas=d["sintomas"],
            quimico=t["quimico"],
            cultural=t["cultural"],
            biologico=t["biologico"],
            preventivo=t["preventivo"],
            urgencia=d["urgencia"],
            fuentes=tuple(d.get("fuentes", [])),
        )
