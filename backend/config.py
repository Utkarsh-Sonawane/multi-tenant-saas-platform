"""
config.py — Application configuration.

All values are read from environment variables so the same Docker image
can be deployed across different tenants and environments.
"""

import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    # ─── Flask ────────────────────────────────────────────────
    SECRET_KEY          = os.getenv("SECRET_KEY", "change-me-in-production")
    DEBUG               = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    TESTING             = False

    # ─── config_db (shared tenant registry database) ─────────
    CONFIG_DB_HOST      = os.getenv("CONFIG_DB_HOST",  "localhost")
    CONFIG_DB_PORT      = int(os.getenv("CONFIG_DB_PORT", "5432"))
    CONFIG_DB_NAME      = os.getenv("CONFIG_DB_NAME",  "config_db")
    CONFIG_DB_USER      = os.getenv("CONFIG_DB_USER",  "postgres")
    CONFIG_DB_PASSWORD  = os.getenv("CONFIG_DB_PASSWORD", "postgres")

    # ─── Tenant DB credentials (injected per namespace) ───────
    # Used to build SQLAlchemy URIs for tenant databases
    TENANT_DB_HOST      = os.getenv("DB_HOST",      "localhost")
    TENANT_DB_PORT      = int(os.getenv("DB_PORT",  "5432"))
    TENANT_DB_USER      = os.getenv("DB_USER",      "postgres")
    TENANT_DB_PASSWORD  = os.getenv("DB_PASSWORD",  "postgres")

    # ─── AWS / Kubernetes metadata ─────────────────────────────
    AWS_REGION          = os.getenv("AWS_REGION",     "ap-south-1")
    K8S_NAMESPACE       = os.getenv("K8S_NAMESPACE",  "default")
    K8S_POD_NAME        = os.getenv("HOSTNAME",        "local-pod")
    ENVIRONMENT         = os.getenv("ENVIRONMENT",     "development")

    # ─── Session / auth ────────────────────────────────────────
    SESSION_COOKIE_HTTPONLY  = True
    SESSION_COOKIE_SAMESITE  = "Lax"
    PERMANENT_SESSION_LIFETIME = 3600   # 1 hour

    # ─── Prometheus ────────────────────────────────────────────
    METRICS_PATH = "/metrics"

    # ─── DB connection pool ────────────────────────────────────
    SQLALCHEMY_POOL_SIZE        = int(os.getenv("DB_POOL_SIZE",    "5"))
    SQLALCHEMY_MAX_OVERFLOW     = int(os.getenv("DB_MAX_OVERFLOW", "10"))
    SQLALCHEMY_POOL_TIMEOUT     = int(os.getenv("DB_POOL_TIMEOUT", "30"))
    SQLALCHEMY_POOL_RECYCLE     = int(os.getenv("DB_POOL_RECYCLE", "1800"))
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    @classmethod
    def get_config_db_uri(cls) -> str:
        return (
            f"postgresql+psycopg2://{cls.CONFIG_DB_USER}:{cls.CONFIG_DB_PASSWORD}"
            f"@{cls.CONFIG_DB_HOST}:{cls.CONFIG_DB_PORT}/{cls.CONFIG_DB_NAME}"
        )

    @classmethod
    def get_tenant_db_uri(cls, db_name: str) -> str:
        """Build a SQLAlchemy URI for a specific tenant database."""
        return (
            f"postgresql+psycopg2://{cls.TENANT_DB_USER}:{cls.TENANT_DB_PASSWORD}"
            f"@{cls.TENANT_DB_HOST}:{cls.TENANT_DB_PORT}/{db_name}"
        )
