FROM python:3.11-slim

WORKDIR /app

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --timeout=300 "tensorflow-cpu>=2.10.0" "numpy>=1.23.0"

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --timeout=300 --no-deps tf_keras

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --timeout=300 "flet>=0.27.0" "Pillow>=9.0.0"

COPY tratamientos.json .
COPY src/ src/

EXPOSE 8550

ENV GLYCINE_ROOT=/app
ENV GLYCINE_WEB=1
ENV GLYCINE_PORT=8550

CMD ["python", "src/main.py"]
