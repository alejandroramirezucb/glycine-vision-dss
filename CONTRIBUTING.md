# Guía de contribución

Gracias por tu interés en contribuir a Glycine Vision DSS. Este documento describe el proceso para participar en el desarrollo.

---

## Antes de contribuir

1. Lee el [Código de Conducta](CODE_OF_CONDUCT.md).
2. Revisa los [issues abiertos](../../issues) para ver si tu propuesta ya existe.
3. Para cambios grandes, abre un issue primero para discutir el enfoque antes de implementar.

---

## Configuración del entorno de desarrollo

### App Flutter

```bash
git clone https://github.com/tu-usuario/glycine-vision-dss.git
cd glycine-vision-dss/App
flutter pub get
flutter analyze
flutter run --release
```

### Servidor Python

```bash
cd Scripts
python -m venv .venv
source .venv/bin/activate  # Windows: .venv\Scripts\activate
pip install -r requirements.txt
python inference_server.py
```

### Notebooks de entrenamiento

Usar Google Colab con GPU T4. Ejecutar los notebooks en orden (01 → 05).

---

## Flujo de trabajo

1. **Fork** el repositorio y clona tu fork.
2. Crea una **rama** descriptiva:
   ```bash
   git checkout -b feature/nombre-de-la-feature
   # o
   git checkout -b fix/descripcion-del-bug
   ```
3. Realiza tus cambios siguiendo las convenciones de código descritas abajo.
4. Verifica que `flutter analyze` no reporta errores.
5. Abre un **Pull Request** contra `main` con una descripción clara.

---

## Convenciones de código

### Dart / Flutter

- Seguir las guías oficiales de estilo Dart.
- Sin comentarios en el código (el código debe ser autoexplicativo mediante nombres descriptivos).
- Aplicar principios SOLID: responsabilidad única, inversión de dependencias.
- Clases públicas documentadas con comentarios de tipo dartdoc si forman parte de una interfaz.
- Nombres en inglés para código; español solo para strings visibles al usuario.
- `flutter analyze` debe pasar sin errores ni warnings antes de cualquier PR.

### Python

- PEP 8 + type hints en funciones públicas.
- Sin comentarios inline innecesarios.
- Funciones con una única responsabilidad.

### Notebooks

- Cada celda con un propósito claro indicado en el título de sección markdown.
- Limpiar outputs antes de hacer commit.

---

## Tipos de contribuciones bienvenidas

- **Bug fixes** — incluir descripción del comportamiento esperado vs observado.
- **Mejoras de rendimiento** — con métricas antes/después.
- **Nuevas clases de patógenos** — requieren dataset y métricas de validación.
- **Mejoras de UI/UX** — mockup o descripción del cambio propuesto.
- **Traducción** — nuevos idiomas en strings de la app.
- **Documentación** — correcciones, ejemplos, traducciones del README.

---

## Reporte de bugs

Al reportar un bug, incluir:

- Versión del sistema operativo y dispositivo
- Versión de Flutter (`flutter --version`)
- Pasos para reproducir el problema
- Comportamiento esperado y observado
- Capturas de pantalla o logs si es posible

---

## Pull Requests

- Descripción clara de qué cambia y por qué.
- Si cierra un issue, mencionar `Closes #número`.
- Un PR por cambio — no mezclar features no relacionadas.
- El PR debe pasar `flutter analyze` sin errores.
