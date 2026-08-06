#!/bin/bash
# ============================================================
# entrypoint.sh — Docker container startup script
#
# 1. Waits for config_db to be reachable
# 2. Launches Gunicorn with prometheus_multiproc_dir
# ============================================================
set -e

echo "======================================================"
echo " Multi-Tenant SaaS Platform — Starting"
echo " Environment : ${ENVIRONMENT:-production}"
echo " Pod/Host    : ${HOSTNAME}"
echo " Region      : ${AWS_REGION:-ap-south-1}"
echo "======================================================"

# ── Wait for config_db ──────────────────────────────────────
CONFIG_DB_HOST="${CONFIG_DB_HOST:-localhost}"
CONFIG_DB_PORT="${CONFIG_DB_PORT:-5432}"
MAX_RETRIES=30
RETRY=0

echo "[init] Waiting for config_db at ${CONFIG_DB_HOST}:${CONFIG_DB_PORT}..."
until python3 -c "
import socket, sys
s = socket.create_connection(('${CONFIG_DB_HOST}', ${CONFIG_DB_PORT}), timeout=3)
s.close()
" 2>/dev/null; do
  RETRY=$((RETRY+1))
  if [ "$RETRY" -ge "$MAX_RETRIES" ]; then
    echo "[ERROR] config_db not reachable after ${MAX_RETRIES} attempts. Exiting."
    exit 1
  fi
  echo "[init] Attempt ${RETRY}/${MAX_RETRIES} — retrying in 2s..."
  sleep 2
done
echo "[init] config_db is reachable ✓"

# ── Prometheus multi-process dir ────────────────────────────
export PROMETHEUS_MULTIPROC_DIR="${PROMETHEUS_MULTIPROC_DIR:-/tmp/prometheus_multiproc}"
mkdir -p "${PROMETHEUS_MULTIPROC_DIR}"
echo "[init] Prometheus multiproc dir: ${PROMETHEUS_MULTIPROC_DIR}"

# ── Launch Gunicorn ─────────────────────────────────────────
WORKERS="${WORKERS:-4}"
WORKER_CLASS="${WORKER_CLASS:-gthread}"
THREADS="${THREADS:-2}"
TIMEOUT="${TIMEOUT:-120}"
PORT="${PORT:-5000}"

echo "[start] Launching Gunicorn — workers=${WORKERS} class=${WORKER_CLASS} threads=${THREADS}"

exec gunicorn \
  --chdir /app \
  --bind "0.0.0.0:${PORT}" \
  --workers "${WORKERS}" \
  --worker-class "${WORKER_CLASS}" \
  --threads "${THREADS}" \
  --timeout "${TIMEOUT}" \
  --keep-alive 5 \
  --max-requests 1000 \
  --max-requests-jitter 100 \
  --access-logfile - \
  --error-logfile - \
  --log-level info \
  --statsd-host "${STATSD_HOST:-}" \
  "backend.app:app"
