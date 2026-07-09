from typing import Optional
import requests

_API_URL = "https://api.open-meteo.com/v1/forecast"
_TIMEOUT_S = 5


def fetch_climate(lat: float, lon: float) -> Optional[dict]:
    try:
        resp = requests.get(
            _API_URL,
            params={
                "latitude": lat,
                "longitude": lon,
                "current": "temperature_2m,relative_humidity_2m,precipitation,dew_point_2m",
                "timezone": "auto",
            },
            timeout=_TIMEOUT_S,
        )
        resp.raise_for_status()
        cur = resp.json().get("current", {})
        return {
            "temp_c": float(cur.get("temperature_2m", 0)),
            "humidity": float(cur.get("relative_humidity_2m", 0)),
            "precip_mm": float(cur.get("precipitation", 0)),
            "dewpoint_c": float(cur.get("dew_point_2m", 0)),
        }
    except Exception:
        return None
