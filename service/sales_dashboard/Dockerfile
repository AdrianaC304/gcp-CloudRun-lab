FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# Cloud Run tells the container which port to listen on with $PORT (8080).
CMD streamlit run app.py --server.port=${PORT:-8080} --server.address=0.0.0.0 --server.headless=true
