"""
logger.py — Structured JSON request logging.

Emits one JSON log line per request containing:
  tenant_id, endpoint, method, request_id, status, duration_ms, timestamp

Usage:
    from logger import get_logger
    log = get_logger(__name__)
    log.info("message", extra={"tenant_id": "tenant-a", "status": 200})
"""

import logging
import sys
import uuid
from pythonjsonlogger import jsonlogger


class _RequestContextFilter(logging.Filter):
    """Injects default keys so every log record has required fields."""

    DEFAULTS = {
        "tenant_id":   "unknown",
        "endpoint":    "-",
        "method":      "-",
        "request_id":  "",
        "status":      "-",
        "duration_ms": 0,
        "environment": "development",
    }

    def filter(self, record: logging.LogRecord) -> bool:
        for key, value in self.DEFAULTS.items():
            if not hasattr(record, key):
                setattr(record, key, value)
        if not record.request_id:
            record.request_id = str(uuid.uuid4())[:8]
        return True


def get_logger(name: str = "app") -> logging.Logger:
    """Return a structed JSON logger."""
    logger = logging.getLogger(name)

    if logger.handlers:
        return logger

    logger.setLevel(logging.INFO)

    handler = logging.StreamHandler(sys.stdout)
    handler.setLevel(logging.INFO)

    formatter = jsonlogger.JsonFormatter(
        fmt="%(asctime)s %(levelname)s %(name)s %(message)s "
            "%(tenant_id)s %(endpoint)s %(method)s "
            "%(request_id)s %(status)s %(duration_ms)s %(environment)s",
        datefmt="%Y-%m-%dT%H:%M:%S",
        rename_fields={"asctime": "timestamp", "levelname": "level", "name": "logger"},
    )
    handler.setFormatter(formatter)
    handler.addFilter(_RequestContextFilter())

    logger.addHandler(handler)
    logger.propagate = False

    return logger


# Default application logger
app_logger = get_logger("app")
