# Política de seguridad

## Versiones soportadas

| Versión | Soporte de seguridad |
|---|---|
| latest (main) | ✅ Activa |
| versiones anteriores | ❌ No soportadas |

---

## Reportar una vulnerabilidad

**No reportes vulnerabilidades de seguridad en issues públicos.**

Si descubres una vulnerabilidad de seguridad en Glycine Vision DSS, envía un reporte por correo electrónico a:

**alejandroramirezvallejos@gmail.com**

Incluye en tu reporte:

- Descripción del tipo de vulnerabilidad
- Pasos para reproducirla
- Impacto potencial
- Cualquier sugerencia de mitigación

### Tiempo de respuesta

- Acuse de recibo: dentro de 48 horas
- Evaluación inicial: dentro de 7 días
- Parche o plan de acción: dentro de 30 días según severidad

---

## Consideraciones de seguridad del sistema

### Privacidad de imágenes

- La inferencia se realiza **completamente en el dispositivo** — las imágenes nunca se envían a servidores externos.
- El servidor Python opcional (`inference_server.py`) procesa imágenes solo en memoria y no las persiste en disco.

### API climática

- Solo se envían coordenadas GPS (latitud/longitud) a la API de Open-Meteo.
- No se transmite ningún dato de imagen ni información personal.

### Modelos de ML

- Los modelos TFLite están embebidos en el bundle de la app y no se actualizan remotamente.
- No existe mecanismo de actualización de modelos over-the-air que pueda introducir modelos maliciosos.

### Servidor FastAPI

- Por defecto el servidor escucha en `0.0.0.0:8001` — **no exponer a internet en producción sin autenticación**.
- No implementa autenticación — usar detrás de un proxy inverso con TLS si se despliega en red.
