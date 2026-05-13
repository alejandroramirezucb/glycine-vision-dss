from typing import Optional


ONSET_TABLE = {
    "roya": {
        "minima":   (2, 5),
        "leve":     (5, 10),
        "moderada": (10, 18),
        "severa":   (18, 28),
        "critica":  (28, 45),
    },
    "fungicas": {
        "minima":   (3, 7),
        "leve":     (7, 14),
        "moderada": (14, 21),
        "severa":   (21, 35),
        "critica":  (35, 55),
    },
    "bacterianas": {
        "minima":   (2, 6),
        "leve":     (6, 12),
        "moderada": (12, 20),
        "severa":   (20, 30),
        "critica":  (30, 45),
    },
    "virales": {
        "minima":   (5, 10),
        "leve":     (10, 18),
        "moderada": (18, 30),
        "severa":   (30, 45),
        "critica":  (45, 70),
    },
    "plagas_insectos": {
        "minima":   (1, 3),
        "leve":     (3, 7),
        "moderada": (7, 14),
        "severa":   (14, 21),
        "critica":  (21, 35),
    },
}


def estimar_onset(clase: str, nivel: str, clima: Optional[dict] = None) -> dict:
    tabla = ONSET_TABLE.get(clase)
    if tabla is None:
        return {"min_days": 0, "max_days": 0, "explanation": "Clase desconocida"}

    base = tabla.get(nivel)
    if base is None:
        return {"min_days": 0, "max_days": 0, "explanation": "Nivel desconocido"}

    min_d, max_d = base
    explanation = f"Rango base para {clase}/{nivel}: {min_d}-{max_d} dias"

    if clima is None:
        return {"min_days": min_d, "max_days": max_d, "explanation": explanation + " (sin clima)"}

    factor = 1.0
    notes = []
    temp = clima["temp_c"]
    hum = clima["humidity"]

    if clase == "roya":
        if hum > 80 and 20 <= temp <= 28:
            factor = 0.7
            notes.append("clima favorable (humedad alta, temperatura optima) acelera onset")
        elif hum < 50:
            factor = 1.3
            notes.append("humedad baja desacelera onset")

    elif clase == "fungicas":
        if hum > 75:
            factor = 0.8
            notes.append("alta humedad acelera fungicas")

    elif clase == "bacterianas":
        if clima["precip_mm"] > 3:
            factor = 0.8
            notes.append("lluvia favorece dispersion bacteriana")

    elif clase == "virales":
        if temp > 28:
            factor = 0.85
            notes.append("temperatura alta favorece vectores")

    elif clase == "plagas_insectos":
        if 24 <= temp <= 32:
            factor = 0.75
            notes.append("temperatura optima acelera ciclo de plaga")

    adj_min = max(1, int(round(min_d * factor)))
    adj_max = max(adj_min + 1, int(round(max_d * factor)))

    final_explanation = explanation
    if notes:
        final_explanation += " | ajuste por clima: " + ", ".join(notes)
        final_explanation += f" -> {adj_min}-{adj_max} dias"

    return {"min_days": adj_min, "max_days": adj_max, "explanation": final_explanation}
