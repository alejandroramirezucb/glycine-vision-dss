import flet as ft

BG_PAGE      = "#E8EDF0"
BG_CARD      = "#FFFFFF"
BORDER       = "#DDE6EA"
ACCENT       = "#1A7F89"
ACCENT_DARK  = "#0F6B73"
ACCENT_LIGHT = "#2A9D97"
TEXT_PRIMARY = "#0A3136"
TEXT_MUTED   = "#4E6A70"
URGENT_CRIT  = "#C0392B"
URGENT_HIGH  = "#E67E22"
URGENT_MED   = "#F39C12"

RADIUS_CARD  = 28
RADIUS_BTN   = 24
RADIUS_CHIP  = 14
RADIUS_IMG   = 22

PHONE_WIDTH  = 390
PHONE_HEIGHT = 720
CARD_WIDTH   = 370
BTN_WIDTH    = 330
BTN_HEIGHT   = 44
IMG_HEIGHT   = 256

def card_shadow() -> list:
    return []

def elevated_shadow() -> list:
    return []

def btn_style(radius: int = RADIUS_BTN) -> ft.ButtonStyle:
    return ft.ButtonStyle(shape=ft.RoundedRectangleBorder(radius=radius), padding=12)

def urgency_color(urgencia: str) -> str:
    return {"critica": URGENT_CRIT, "alta": URGENT_HIGH}.get(urgencia.lower(), URGENT_MED)
