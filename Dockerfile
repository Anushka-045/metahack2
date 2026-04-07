# ── Hugging Face Spaces compatible Dockerfile ────────────────────────────────
# HF Spaces runs as a non-root user and expects port 7860.
FROM python:3.11-slim

# Metadata
LABEL maintainer="Anushka"
LABEL description="Compliance Monitor — Data Pipeline"
LABEL version="1.0.0"

WORKDIR /app

# System deps — curl for healthcheck, build-essential for compiled wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Install Python deps first (layer cache)
COPY requirements_anushka.txt ./requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Create writable directories for SQLite and any temp files
RUN mkdir -p /app/data /app/tmp \
    && chmod 777 /app/data /app/tmp

# Non-root user (required by HF Spaces)
RUN useradd -m -u 1000 appuser \
    && chown -R appuser:appuser /app
USER appuser

# Environment
ENV PYTHONUNBUFFERED=1
ENV DB_PATH=/app/data/compliance_db.sqlite
ENV PORT=7860

# Expose HF Spaces default port
EXPOSE 7860

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
    CMD curl -f http://localhost:7860/health || exit 1

# Start — HF Spaces picks up app.py
CMD ["python", "app.py"]
