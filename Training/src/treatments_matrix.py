import json
from pathlib import Path


TRATAMIENTOS_MATRIX = {
    "bacterianas": {
        "nombre_es": "Enfermedades Bacterianas",
        "patogenos": "Pseudomonas savastanoi pv. glycinea, Xanthomonas axonopodis pv. glycines",
        "sintomas": "Manchas angulares acuosas que se necrosan; halos amarillentos; lesiones limitadas por nervaduras.",
        "fuentes": [
            {"texto": "SENASAG Bolivia - Manejo de enfermedades en soya", "url": "https://www.senasag.gob.bo"},
            {"texto": "Embrapa - Doencas bacterianas da soja", "url": "https://www.embrapa.br/soja"},
        ],
        "por_severidad": {
            "minima": {
                "quimico": "Cobre oxiclorido 50 WP - 300 g/100 L agua (preventivo).",
                "cultural": "Mejorar drenaje del lote. Evitar riego por aspersion.",
                "biologico": "Bacillus subtilis QST 713 - aplicacion foliar 100 mL/100 L.",
                "preventivo": "Semilla certificada. Rotacion con maiz o sorgo.",
                "urgencia": "baja",
            },
            "leve": {
                "quimico": "Cobre 50 WP + Mancozeb 80 WP - 400 g + 200 g/100 L.",
                "cultural": "Eliminar hojas muy afectadas. No trabajar el lote con hojas mojadas.",
                "biologico": "Bacillus subtilis cada 7 dias.",
                "preventivo": "Monitoreo semanal. Aplicar antes de lluvias previstas.",
                "urgencia": "media",
            },
            "moderada": {
                "quimico": "Kasugamicina 2 SL 100 mL/100 L + Cobre 300 g/100 L. Repetir cada 7 dias x 3 ciclos.",
                "cultural": "Suspender riego por aspersion. Mejorar ventilacion entre plantas.",
                "biologico": "Bacillus subtilis + Pseudomonas fluorescens.",
                "preventivo": "Notificar tecnico. Revisar lotes vecinos.",
                "urgencia": "alta",
            },
            "severa": {
                "quimico": "Streptomicina 15 WP 100 g/100 L + Cobre oxiclorido 400 g/100 L cada 5-7 dias.",
                "cultural": "Eliminar plantas con >50% hojas afectadas. Desinfectar herramientas con hipoclorito 1%.",
                "biologico": "Suspender control biologico solo durante el ataque quimico intenso.",
                "preventivo": "Evaluar cosecha anticipada si esta en R6.",
                "urgencia": "alta",
            },
            "critica": {
                "quimico": "Control quimico ya insuficiente. Aplicar Streptomicina + Cobre solo para limitar dispersion.",
                "cultural": "Eliminar plantas afectadas. Cuarentena del area. Rotar cultivo proxima campania.",
                "biologico": "Suspender. Reanudar tras erradicacion.",
                "preventivo": "Desinfectar herramientas y vestimenta. Notificar SENASAG.",
                "urgencia": "critica",
            },
        },
    },
    "fungicas": {
        "nombre_es": "Enfermedades Fungicas",
        "patogenos": "Cercospora kikuchii, Septoria glycines, Corynespora cassiicola, Cercospora sojina",
        "sintomas": "Manchas circulares o irregulares marron-rojizas; necrosis con halo clorotico; defoliacion progresiva.",
        "fuentes": [
            {"texto": "Embrapa Soja - Doencas fungicas", "url": "https://www.embrapa.br/soja/doencas"},
            {"texto": "APS - Soybean Diseases", "url": "https://www.apsnet.org"},
        ],
        "por_severidad": {
            "minima": {
                "quimico": "Azufre coloidal 80 WP - 300 g/100 L preventivo.",
                "cultural": "Mejorar ventilacion entre surcos. No aplicar con temperatura >35 C.",
                "biologico": "Trichoderma harzianum - aplicacion foliar y al suelo.",
                "preventivo": "Variedades tolerantes. Monitoreo desde V4.",
                "urgencia": "baja",
            },
            "leve": {
                "quimico": "Mancozeb 80 WP 200-250 g/100 L cada 10-12 dias desde primeros sintomas.",
                "cultural": "Aplicar en horas frescas (mañana o tarde). Cobertura total.",
                "biologico": "Trichoderma + Bacillus subtilis.",
                "preventivo": "Alternar principios activos para evitar resistencia.",
                "urgencia": "media",
            },
            "moderada": {
                "quimico": "Tebuconazol 25 EC 75-100 mL/100 L + Mancozeb 200 g/100 L cada 10 dias x 2-3 aplicaciones.",
                "cultural": "Eliminar hojas basales afectadas. Revisar densidad de siembra.",
                "biologico": "Mantener Trichoderma como complemento.",
                "preventivo": "Monitoreo lotes vecinos.",
                "urgencia": "alta",
            },
            "severa": {
                "quimico": "Trifloxistrobina 50 WG 75 g/100 L + Tebuconazol 25 EC 75 mL/100 L cada 7 dias (max 3 aplicaciones/campania).",
                "cultural": "Revisar lote completo. Evaluar perdida economica.",
                "biologico": "Suspender durante ataque quimico intenso.",
                "preventivo": "Notificar tecnico agronomo.",
                "urgencia": "alta",
            },
            "critica": {
                "quimico": "Fluxapiroxad 20 SC 60 mL/100 L + Mancozeb 200 g/100 L cada 5 dias hasta controlar.",
                "cultural": "Evaluar cosecha anticipada si esta en R6 o posterior.",
                "biologico": "Suspender.",
                "preventivo": "Variedades resistentes proxima campania.",
                "urgencia": "critica",
            },
        },
    },
    "roya": {
        "nombre_es": "Roya Asiatica de la Soya",
        "patogenos": "Phakopsora pachyrhizi",
        "sintomas": "Pustulas pequeñas marron-rojizas en enves; clorosis y defoliacion rapida; perdida de rendimiento >50% si no se controla.",
        "fuentes": [
            {"texto": "Consorcio Antirroya Brasil", "url": "https://www.consorcioantiferrugem.net"},
            {"texto": "Embrapa - Ferrugem da soja", "url": "https://www.embrapa.br/soja/ferrugem"},
        ],
        "por_severidad": {
            "minima": {
                "quimico": "Tebuconazol 25 EC 75 mL/100 L PREVENTIVO desde R1.",
                "cultural": "Monitoreo cada 5 dias. Eliminar soyas voluntarias (puente verde).",
                "biologico": "Bacillus subtilis QST 713 como complemento.",
                "preventivo": "CRITICO: aplicar antes que avance. Roya puede destruir cultivo en 2-3 semanas.",
                "urgencia": "media",
            },
            "leve": {
                "quimico": "Azoxistrobina 25 SC 80 mL/100 L + Tebuconazol 25 EC 75 mL/100 L cada 10-12 dias.",
                "cultural": "Aplicar antes de lluvia. Usar adyuvante/adherente para mejor cobertura.",
                "biologico": "Mantener Bacillus subtilis.",
                "preventivo": "Avisar a vecinos del lote.",
                "urgencia": "alta",
            },
            "moderada": {
                "quimico": "Picoxistrobina + Ciproconazol (Priori Xtra) 300 mL/ha cada 10 dias x 2 ciclos minimo.",
                "cultural": "Monitoreo diario 48 hs post-aplicacion. Cobertura toda la planta.",
                "biologico": "Suspender durante ataque quimico intenso.",
                "preventivo": "Coordinar con vecinos para aplicacion regional.",
                "urgencia": "alta",
            },
            "severa": {
                "quimico": "Fluxapiroxad + Piraclostrobina (Opera Ultra) dosis alta cada 7 dias.",
                "cultural": "EMERGENCIA. Notificar tecnico agronomo. Monitoreo diario.",
                "biologico": "Suspender.",
                "preventivo": "Evaluar perdida proyectada.",
                "urgencia": "critica",
            },
            "critica": {
                "quimico": "Triazol + estrobilurina + protectante en dosis maximas cada 5-7 dias.",
                "cultural": "Si esta en R6, evaluar cosecha anticipada. Perdida probable >50%.",
                "biologico": "Suspender.",
                "preventivo": "NOTIFICAR SENASAG. Variedades resistentes proxima campania.",
                "urgencia": "critica",
            },
        },
    },
    "virales": {
        "nombre_es": "Enfermedades Virales",
        "patogenos": "Soybean Mosaic Virus (SMV), Bean Pod Mottle Virus (BPMV)",
        "sintomas": "Mosaico clorotico, deformacion foliar, vainas moteadas, retraso de crecimiento.",
        "fuentes": [
            {"texto": "Iowa State - Soybean Virus Diseases", "url": "https://crops.extension.iastate.edu"},
            {"texto": "APS - Viral Diseases of Soybean", "url": "https://www.apsnet.org"},
        ],
        "por_severidad": {
            "minima": {
                "quimico": "No hay cura viral. Control de vectores: Aceite de neem 1% + Imidacloprid 35 SC 60 mL/100 L.",
                "cultural": "Eliminar malezas hospederas. Controlar afidos y mosca blanca.",
                "biologico": "Trampas amarillas pegajosas. Liberar Encarsia formosa para mosca blanca.",
                "preventivo": "Semilla certificada libre de virus. Variedades tolerantes.",
                "urgencia": "media",
            },
            "leve": {
                "quimico": "Imidacloprid 35 SC 60 mL/100 L + Thiamethoxam 25 WG 80 g/100 L cada 7-10 dias.",
                "cultural": "Eliminar plantas muy afectadas. Controlar malezas.",
                "biologico": "Mantener trampas y enemigos naturales en bordes.",
                "preventivo": "Revisar fuente de semilla.",
                "urgencia": "alta",
            },
            "moderada": {
                "quimico": "Thiamethoxam 25 WG 100 g/100 L + Clorpirifos 48 EC 150 mL/100 L cada 7 dias.",
                "cultural": "Eliminar todas las plantas sintomaticas del area central.",
                "biologico": "Barrera insecticida perimetro.",
                "preventivo": "Evaluar perdida economica.",
                "urgencia": "alta",
            },
            "severa": {
                "quimico": "Continuar control de vectores intensivo.",
                "cultural": "Eliminar plantas infectadas. Aplicar insecticida al suelo. Limpiar herramientas con hipoclorito.",
                "biologico": "Suspender.",
                "preventivo": "Notificar tecnico.",
                "urgencia": "critica",
            },
            "critica": {
                "quimico": "Continuar control de vectores.",
                "cultural": "Destruccion del lote infectado. Cuarentena. Certificar semillas proxima campania.",
                "biologico": "Suspender.",
                "preventivo": "NO usar semillas propias. Notificar SENASAG.",
                "urgencia": "critica",
            },
        },
    },
    "plagas_insectos": {
        "nombre_es": "Plagas de Insectos",
        "patogenos": "Anticarsia gemmatalis, Spodoptera spp., Diabrotica speciosa, Bemisia tabaci",
        "sintomas": "Defoliacion, perforaciones en hojas, daños en vainas, raices o tallos; presencia visible de larvas o adultos.",
        "fuentes": [
            {"texto": "Embrapa - Manejo integrado de pragas", "url": "https://www.embrapa.br/soja/mip"},
            {"texto": "INIAF Bolivia - Plagas de la soya", "url": "https://www.iniaf.gob.bo"},
        ],
        "por_severidad": {
            "minima": {
                "quimico": "No requiere quimico. Aplicar solo si supera umbral.",
                "cultural": "Trampas amarillas y de feromonas. Revisar bordes del lote.",
                "biologico": "Bacillus thuringiensis (Dipel WP) 100 g/100 L + Trichogramma para huevos.",
                "preventivo": "Monitoreo semanal con paño de batida.",
                "urgencia": "baja",
            },
            "leve": {
                "quimico": "Spinosad 480 SC 20-30 mL/100 L cada 10 dias x 2 aplicaciones.",
                "cultural": "Aplicar al atardecer para mayor contacto con larvas.",
                "biologico": "Mantener Bt + Trichogramma.",
                "preventivo": "Rotacion con maiz o sorgo.",
                "urgencia": "media",
            },
            "moderada": {
                "quimico": "Clorpirifos 48 EC 150 mL/100 L + Bt 100 g/100 L cada 7 dias.",
                "cultural": "Monitoreo diario de densidad de plaga.",
                "biologico": "Liberacion masiva de Trichogramma.",
                "preventivo": "Evaluar daño economico.",
                "urgencia": "alta",
            },
            "severa": {
                "quimico": "Lambda-cialotrina 5 EC 100-150 mL/100 L cada 5-7 dias - rotar con otro activo.",
                "cultural": "Evitar aplicar cerca de cosecha (respetar carencia).",
                "biologico": "Suspender durante ataque quimico intenso.",
                "preventivo": "Notificar vecinos.",
                "urgencia": "alta",
            },
            "critica": {
                "quimico": "Lambda-cialotrina 5 EC 100 mL/100 L + Clorpirifos 150 mL/100 L cada 4-5 dias.",
                "cultural": "Evaluar perdida economica. Control biologico masivo posterior.",
                "biologico": "Reanudar tras controlar pico.",
                "preventivo": "Variedades menos susceptibles proxima campania.",
                "urgencia": "critica",
            },
        },
    },
}


def exportar_a_json(out_path: str) -> None:
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(TRATAMIENTOS_MATRIX, f, ensure_ascii=False, indent=2)


def obtener_tratamiento(clase: str, nivel: str) -> dict:
    entrada = TRATAMIENTOS_MATRIX.get(clase, {})
    por_sev = entrada.get("por_severidad", {})
    return por_sev.get(nivel, por_sev.get("moderada", {}))
