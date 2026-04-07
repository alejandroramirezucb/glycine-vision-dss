from dataclasses import dataclass


@dataclass(frozen=True)
class TreatmentInfo:
    disease_key: str
    nombre_es:   str
    patogenos:   str
    sintomas:    str
    quimico:     str
    cultural:    str
    biologico:   str
    preventivo:  str
    urgencia:    str
    fuentes:     tuple[str, ...]
