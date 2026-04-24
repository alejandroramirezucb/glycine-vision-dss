FROM python:3.11-slim

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY tratamientos.json .
COPY src/ src/

EXPOSE 8550

ENV GLYCINE_ROOT=/app
ENV GLYCINE_WEB=1
ENV GLYCINE_PORT=8550

CMD ["python", "src/main.py"]
