FROM python:3.9-slim

WORKDIR /app

# Copy requirements first for better caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application code
COPY . .

# Expose ports for web dashboard and WebSocket server
EXPOSE 9090 9191

# Set environment variables
ENV FLASK_HOST=0.0.0.0
ENV FLASK_PORT=9090
ENV ARUBA_WS_HOST=0.0.0.0
ENV ARUBA_WS_PORT=9191
ENV FLASK_DEBUG=False

# Command to run the application
CMD ["python", "app.py"]
