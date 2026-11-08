FROM python:3.12-slim

WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# A job has no web server: it runs this command and stops.
CMD ["python", "main.py"]
