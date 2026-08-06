# ============================================================
# Dockerfile — Multi-Tenant SaaS Platform
# Single image serves ALL tenants. Tenant routing is config-driven.
#
# Build:  docker build -f docker/Dockerfile -t multi-tenant-saas:latest .
# Run:    docker run -p 5000:5000 --env-file docker/.env multi-tenant-saas:latest
# ============================================================

# ── Stage 1: Builder ──────────────────────────────────────────
FROM python:3.12-slim AS builder

WORKDIR /build

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Copy and install Python deps into a prefix directory
COPY backend/requirements.txt .
RUN pip install --upgrade pip \
 && pip install --prefix=/install --no-cache-dir -r requirements.txt

# ── Stage 2: Production runtime ───────────────────────────────
FROM python:3.12-slim AS runtime

LABEL maintainer="devops@example.com" \
      description="Multi-Tenant SaaS Platform — Amazon EKS Demo" \
      version="1.0.0"

# Non-root user for security
RUN groupadd -r saas && useradd -r -g saas -u 1001 saas

WORKDIR /app

# Runtime OS libs only
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy installed packages from builder
COPY --from=builder /install /usr/local

# Copy application code
COPY backend/    ./backend/
COPY frontend/   ./frontend/

# Copy entrypoint
COPY docker/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Set ownership
RUN chown -R saas:saas /app

# Switch to non-root
USER saas

# Environment defaults (overridden by Kubernetes ConfigMap / Secret)
ENV PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    FLASK_APP=backend/app.py \
    FLASK_DEBUG=false \
    PORT=5000 \
    WORKERS=4 \
    WORKER_CLASS=gthread \
    THREADS=2 \
    TIMEOUT=120 \
    ENVIRONMENT=production \
    AWS_REGION=ap-south-1

# Expose application port
EXPOSE 5000

# Health check (Kubernetes liveness probe backup)
HEALTHCHECK --interval=30s --timeout=10s --start-period=15s --retries=3 \
  CMD curl -f http://localhost:5000/healthz || exit 1

ENTRYPOINT ["/entrypoint.sh"]
