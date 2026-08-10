# Política de seguridad

## Versiones soportadas

| Versión | Soporte |
|---|---|
| `main` | Activo |
| Etiquetas anteriores | Sin soporte |

## Reportar una vulnerabilidad

**No abras una incidencia pública para reportar una vulnerabilidad.**

Escribe a **alejandroramirezvallejos@gmail.com** con:

- El tipo de vulnerabilidad y el componente afectado.
- Pasos para reproducirla.
- El impacto que consideras posible.
- Cualquier mitigación que hayas identificado.

| Etapa | Plazo |
|---|---|
| Acuse de recibo | 48 horas |
| Evaluación inicial | 7 días |
| Parche o plan de acción | 30 días, según la severidad |

## Modelo de amenaza

### Imágenes y privacidad

La inferencia ocurre íntegramente en el dispositivo: las imágenes **no se transmiten**. El backend FastAPI es opcional y no forma parte del flujo de la aplicación; cuando se usa, procesa las imágenes en memoria y no las persiste.

### Servicio climático

A Open-Meteo se envían únicamente coordenadas geográficas. No se transmite ninguna imagen ni dato personal. La petición no lleva credenciales, por lo que no hay secretos que filtrar por esta vía.

### Modelos

Los modelos TFLite se empaquetan con la aplicación y **no se actualizan de forma remota**. No existe un canal de actualización over-the-air que pudiera usarse para introducir un modelo manipulado.

### Backend FastAPI

Estas son las condiciones bajo las que se distribuye, y son deliberadas:

- Escucha en `0.0.0.0:8001` y **no implementa autenticación**. Está pensado para uso local o tras un proxy inverso con TLS y control de acceso. **No lo expongas directamente a internet.**
- CORS se restringe a `localhost` salvo que se defina `CORS_ORIGINS`.
- Las cargas se limitan a 10 MB por defecto (`MAX_UPLOAD_BYTES`) y las imágenes se reescalan a 400 px de lado máximo antes de procesarse.

## Fuera de alcance

Lo siguiente no se considera vulnerabilidad de seguridad, aunque sí puede ser una incidencia legítima:

- Un diagnóstico incorrecto o una estimación de severidad imprecisa. Son limitaciones del modelo, documentadas en [`docs/model-card.md`](docs/model-card.md).
- La ausencia de autenticación en el backend cuando se despliega tal cual, dado que está documentada arriba.
- Que las recomendaciones fitosanitarias no se ajusten a una normativa local concreta. El sistema declara explícitamente que son orientativas.
