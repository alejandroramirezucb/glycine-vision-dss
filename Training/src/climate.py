import requests
from typing import Optional


OPEN_METEO_URL = "https://api.open-meteo.com/v1/forecast"


def fetch_climate(lat: float, lon: float, timeout: float = 5.0) -> Optional[dict]:
    try:
        params = {
            "latitude": lat,
            "longitude": lon,
            "current": "temperature_2m,relative_humidity_2m,precipitation,dew_point_2m",
            "timezone": "auto",
        }
        r = requests.get(OPEN_METEO_URL, params=params, timeout=timeout)
        r.raise_for_status()
        data = r.json().get("current", {})
        return {
            "temp_c": float(data.get("temperature_2m", 0.0)),
            "humidity": float(data.get("relative_humidity_2m", 0.0)),
            "precip_mm": float(data.get("precipitation", 0.0)),
            "dewpoint_c": float(data.get("dew_point_2m", 0.0)),
        }
    except Exception:
        return None


def riesgo_por_clima(clase: str, clima: Optional[dict]) -> float:
    if clima is None:
        return 0.5
    temp = clima["temp_c"]
    hum = clima["humidity"]
    precip = clima["precip_mm"]

    if clase == "roya":
        ok_temp = 1.0 if 18 <= temp <= 28 else 0.4
        ok_hum = min(hum / 80.0, 1.0)
        ok_precip = min(precip / 5.0, 1.0) * 0.5 + 0.5
        return float(min(ok_temp * ok_hum * ok_precip, 1.0))

    if clase == "fungicas":
        ok_temp = 1.0 if 20 <= temp <= 30 else 0.5
        ok_hum = min(hum / 75.0, 1.0)
        return float(min(ok_temp * ok_hum, 1.0))

    if clase == "bacterianas":
        ok_temp = 1.0 if 22 <= temp <= 32 else 0.5
        ok_precip = min(precip / 3.0, 1.0) * 0.6 + 0.4
        return float(min(ok_temp * ok_precip, 1.0))

    if clase == "virales":
        ok_temp = 1.0 if 25 <= temp <= 35 else 0.5
        ok_hum_inv = 1.0 - min(max(hum - 50, 0) / 50.0, 0.4)
        return float(min(ok_temp * ok_hum_inv, 1.0))

    if clase == "plagas_insectos":
        ok_temp = 1.0 if 24 <= temp <= 34 else 0.4
        ok_hum = 1.0 if 40 <= hum <= 70 else 0.7
        return float(min(ok_temp * ok_hum, 1.0))

    return 0.5
