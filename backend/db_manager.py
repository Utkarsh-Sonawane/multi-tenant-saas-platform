"""
db_manager.py — Dynamic multi-tenant SQLAlchemy engine & session registry.

How it works:
  1. A single engine connects to config_db on startup.
  2. When a request arrives for /tenant-a, tenant-b, or tenant-c:
     a. The tenant's row is fetched from config_db.tenant_config.
     b. A per-tenant SQLAlchemy engine is created (or returned from cache).
     c. Queries are run against that tenant's database dynamically.

No hardcoded tenant logic lives here. All routing is data-driven.
"""

from __future__ import annotations

import sys
import os
import time
from threading import Lock
from typing import Any

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker, Session
from sqlalchemy.pool import QueuePool

from config import Config
import metrics as prom
from logger import get_logger

log = get_logger("db_manager")

# ─── Config DB (single shared engine) ─────────────────────────────────────────

_config_engine = create_engine(
    Config.get_config_db_uri(),
    pool_size=5,
    max_overflow=5,
    pool_pre_ping=True,
    pool_recycle=1800,
)
ConfigSession = sessionmaker(bind=_config_engine)


# ─── Tenant engine cache ───────────────────────────────────────────────────────

_tenant_engines: dict[str, Any] = {}
_tenant_configs: dict[str, dict] = {}
_cache_lock = Lock()

DEFAULT_TENANT_CONFIGS: list[dict[str, Any]] = [
    {
        "tenant_id": "tenant-a",
        "tenant_name": "Tenant A",
        "company_name": "ABC Retail",
        "theme_color": "#0d6efd",
        "company_logo": "/static/logos/abc_retail.png",
        "db_host": Config.TENANT_DB_HOST,
        "db_port": Config.TENANT_DB_PORT,
        "db_name": "tenant_a_db",
        "db_username": Config.TENANT_DB_USER,
        "namespace": "tenant-a",
        "service_name": "tenant-a-service",
        "ingress_path": "/tenant-a",
        "status": "active",
        "modules_enabled": ["Products", "Orders", "Customers"],
    },
    {
        "tenant_id": "tenant-b",
        "tenant_name": "Tenant B",
        "company_name": "XYZ Hospital",
        "theme_color": "#198754",
        "company_logo": "/static/logos/xyz_hospital.png",
        "db_host": Config.TENANT_DB_HOST,
        "db_port": Config.TENANT_DB_PORT,
        "db_name": "tenant_b_db",
        "db_username": Config.TENANT_DB_USER,
        "namespace": "tenant-b",
        "service_name": "tenant-b-service",
        "ingress_path": "/tenant-b",
        "status": "active",
        "modules_enabled": ["Patients", "Doctors", "Appointments"],
    },
    {
        "tenant_id": "tenant-c",
        "tenant_name": "Tenant C",
        "company_name": "PQR School",
        "theme_color": "#fd7e14",
        "company_logo": "/static/logos/pqr_school.png",
        "db_host": Config.TENANT_DB_HOST,
        "db_port": Config.TENANT_DB_PORT,
        "db_name": "tenant_c_db",
        "db_username": Config.TENANT_DB_USER,
        "namespace": "tenant-c",
        "service_name": "tenant-c-service",
        "ingress_path": "/tenant-c",
        "status": "active",
        "modules_enabled": ["Students", "Teachers", "Attendance"],
    },
]


def _fallback_tenant_config(tenant_id: str) -> dict | None:
    for tenant in DEFAULT_TENANT_CONFIGS:
        if tenant["tenant_id"] == tenant_id:
            return dict(tenant)
    return None


def get_active_tenant_configs() -> list[dict]:
    """Return active tenant configs from config_db or a static demo fallback."""
    try:
        session = ConfigSession()
        try:
            rows = session.execute(
                text(
                    "SELECT tenant_id, tenant_name, company_name, theme_color, "
                    "company_logo, db_host, db_port, db_name, db_username, "
                    "namespace, service_name, ingress_path, status, modules_enabled "
                    "FROM tenant_config WHERE status = 'active' ORDER BY id"
                )
            ).mappings().fetchall()
            tenants = [dict(r) for r in rows]
        finally:
            session.close()

        if tenants:
            return tenants
    except Exception as exc:
        log.error("Failed to load active tenant configs", exc_info=exc)

    for tenant in DEFAULT_TENANT_CONFIGS:
        _tenant_configs[tenant["tenant_id"]] = dict(tenant)
    return [dict(tenant) for tenant in DEFAULT_TENANT_CONFIGS]


def get_tenant_config(tenant_id: str) -> dict | None:
    """
    Fetch a tenant's configuration row from config_db.tenant_config.
    Results are cached in memory; cache is refreshed on every Flask start.
    """
    with _cache_lock:
        if tenant_id in _tenant_configs:
            prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="hit").inc()
            return _tenant_configs[tenant_id]

    try:
        t0 = time.perf_counter()
        session = ConfigSession()
        try:
            row = session.execute(
                text(
                    "SELECT tenant_id, tenant_name, company_name, theme_color, "
                    "company_logo, db_host, db_port, db_name, db_username, "
                    "namespace, service_name, ingress_path, status, modules_enabled "
                    "FROM tenant_config WHERE tenant_id = :tid AND status = 'active'"
                ),
                {"tid": tenant_id},
            ).mappings().fetchone()
        finally:
            session.close()
        duration = time.perf_counter() - t0
        prom.record_db_query(tenant_id, "config_lookup", duration)

        if not row:
            fallback = _fallback_tenant_config(tenant_id)
            if fallback:
                with _cache_lock:
                    _tenant_configs[tenant_id] = dict(fallback)
                prom.mark_tenant_active(tenant_id, fallback["company_name"], True)
                prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="miss").inc()
                return dict(fallback)

            log.warning(
                "Tenant not found or inactive",
                extra={"tenant_id": tenant_id},
            )
            prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="miss").inc()
            return None

        cfg = dict(row)
        with _cache_lock:
            _tenant_configs[tenant_id] = cfg

        prom.mark_tenant_active(tenant_id, cfg["company_name"], True)
        prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="miss").inc()
        return cfg

    except Exception as exc:
        fallback = _fallback_tenant_config(tenant_id)
        if fallback:
            with _cache_lock:
                _tenant_configs[tenant_id] = dict(fallback)
            prom.mark_tenant_active(tenant_id, fallback["company_name"], True)
            prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="error").inc()
            return dict(fallback)

        log.error(
            "Failed to load tenant config",
            extra={"tenant_id": tenant_id},
            exc_info=exc,
        )
        prom.TENANT_CONFIG_LOADS.labels(tenant_id=tenant_id, result="error").inc()
        return None


def get_tenant_session(tenant_id: str, db_name: str) -> Session:
    """
    Return a SQLAlchemy Session connected to the tenant's own database.
    Engines are pooled and reused across requests.
    """
    cache_key = f"{tenant_id}::{db_name}"

    with _cache_lock:
        if cache_key not in _tenant_engines:
            uri = Config.get_tenant_db_uri(db_name)
            engine = create_engine(
                uri,
                poolclass=QueuePool,
                pool_size=Config.SQLALCHEMY_POOL_SIZE,
                max_overflow=Config.SQLALCHEMY_MAX_OVERFLOW,
                pool_timeout=Config.SQLALCHEMY_POOL_TIMEOUT,
                pool_recycle=Config.SQLALCHEMY_POOL_RECYCLE,
                pool_pre_ping=True,
            )
            _tenant_engines[cache_key] = engine
            log.info(
                "Created new tenant DB engine",
                extra={"tenant_id": tenant_id, "endpoint": db_name},
            )

    engine = _tenant_engines[cache_key]
    prom.set_db_connections(
        tenant_id, db_name,
        engine.pool.checkedout() if hasattr(engine.pool, "checkedout") else 0,
    )
    return sessionmaker(bind=engine)()


# ─── Dynamic table query helpers ──────────────────────────────────────────────

# Maps module name → (table_name, display columns, sort column)
MODULE_TABLE_MAP: dict[str, tuple[str, list[str], str]] = {
    # Tenant A — Retail
    "Products": (
        "products",
        ["id", "name", "category", "sku", "price", "stock_qty", "status"],
        "id",
    ),
    "Orders": (
        "orders",
        ["id", "customer_id", "product_id", "quantity", "total_price", "order_status", "order_date"],
        "order_date",
    ),
    "Customers": (
        "customers",
        ["id", "first_name", "last_name", "email", "phone", "city", "status"],
        "id",
    ),
    # Tenant B — Healthcare
    "Patients": (
        "patients",
        ["id", "first_name", "last_name", "date_of_birth", "gender", "blood_group", "city", "status"],
        "id",
    ),
    "Doctors": (
        "doctors",
        ["id", "first_name", "last_name", "specialization", "department", "experience_yrs", "status"],
        "id",
    ),
    "Appointments": (
        "appointments",
        ["id", "patient_id", "doctor_id", "appointment_date", "appointment_time", "reason", "status"],
        "appointment_date",
    ),
    # Tenant C — Education
    "Students": (
        "students",
        ["id", "first_name", "last_name", "roll_number", "class_grade", "section", "gender", "status"],
        "id",
    ),
    "Teachers": (
        "teachers",
        ["id", "first_name", "last_name", "subject", "department", "experience_yrs", "status"],
        "id",
    ),
    "Attendance": (
        "attendance",
        ["id", "student_id", "attendance_date", "status", "remarks"],
        "attendance_date",
    ),
}

# Primary "dashboard" module per tenant (first module)
DASHBOARD_MODULE_MAP: dict[str, str] = {
    "tenant-a": "Products",
    "tenant-b": "Patients",
    "tenant-c": "Students",
}


def fetch_table_data(
    tenant_id: str,
    db_name: str,
    module: str,
    limit: int = 10,
    offset: int = 0,
    search: str = "",
) -> dict:
    """
    Dynamically query a module's table and return rows + count.
    No tenant-specific code — all driven by MODULE_TABLE_MAP.
    """
    if module not in MODULE_TABLE_MAP:
        return {"rows": [], "total": 0, "columns": [], "error": "Unknown module"}

    table, columns, sort_col = MODULE_TABLE_MAP[module]
    cols_sql = ", ".join(f'"{c}"' for c in columns)

    # Build optional search WHERE clause against text columns
    where_clause = ""
    params: dict = {"limit": limit, "offset": offset}

    if search:
        # Attempt text search on first 3 string-type columns
        text_cols = [c for c in columns if c not in ("id", "price", "quantity",
                      "total_price", "stock_qty", "experience_yrs")][:3]
        if text_cols:
            clauses = " OR ".join(f'CAST("{c}" AS TEXT) ILIKE :search' for c in text_cols)
            where_clause = f"WHERE {clauses}"
            params["search"] = f"%{search}%"

    count_sql  = f'SELECT COUNT(*) FROM "{table}" {where_clause}'
    select_sql = (
        f'SELECT {cols_sql} FROM "{table}" {where_clause} '
        f'ORDER BY "{sort_col}" DESC LIMIT :limit OFFSET :offset'
    )

    try:
        t0 = time.perf_counter()
        session = get_tenant_session(tenant_id, db_name)
        try:
            total = session.execute(text(count_sql), params).scalar()
            rows  = [dict(r) for r in session.execute(text(select_sql), params).mappings()]
        finally:
            session.close()
        duration = time.perf_counter() - t0
        prom.record_db_query(tenant_id, f"fetch_{table}", duration)
        return {"rows": rows, "total": total, "columns": columns}

    except Exception as exc:
        log.error(
            "fetch_table_data failed",
            extra={"tenant_id": tenant_id, "endpoint": table},
            exc_info=exc,
        )
        return {"rows": [], "total": 0, "columns": columns, "error": str(exc)}


def get_table_counts(tenant_id: str, db_name: str, modules: list[str]) -> dict[str, int]:
    """Return row counts for all enabled modules (used for dashboard cards)."""
    counts: dict[str, int] = {}
    for module in modules:
        if module not in MODULE_TABLE_MAP:
            continue
        table, _, _ = MODULE_TABLE_MAP[module]
        try:
            session = get_tenant_session(tenant_id, db_name)
            try:
                count = session.execute(text(f'SELECT COUNT(*) FROM "{table}"')).scalar()
            finally:
                session.close()
            counts[module] = count or 0
        except Exception as exc:
            log.error(
                "Count query failed",
                extra={"tenant_id": tenant_id, "endpoint": table},
                exc_info=exc,
            )
            counts[module] = 0
    return counts


def get_chart_data(tenant_id: str, db_name: str, modules: list[str]) -> dict:
    """
    Return chart-friendly datasets for Chart.js.
    Dynamically selects queries based on available modules.
    """
    chart = {"labels": [], "datasets": []}

    primary_module = modules[0] if modules else None
    if not primary_module or primary_module not in MODULE_TABLE_MAP:
        return chart

    table, columns, _ = MODULE_TABLE_MAP[primary_module]

    try:
        session = get_tenant_session(tenant_id, db_name)
        try:
            # Generic grouping: group by last column that has 'status' or 'category'
            group_col = next(
                (c for c in columns if c in ("status", "category", "order_status",
                  "gender", "department", "specialization", "class_grade", "blood_group")),
                None
            )
            if group_col:
                rows = session.execute(
                    text(f'SELECT "{group_col}" AS label, COUNT(*) AS count '
                         f'FROM "{table}" GROUP BY "{group_col}" ORDER BY count DESC LIMIT 8')
                ).fetchall()
                chart["labels"]   = [r.label for r in rows]
                chart["datasets"] = [{"label": f"{primary_module} by {group_col}",
                                       "data": [r.count for r in rows]}]
        finally:
            session.close()
    except Exception as exc:
        log.error(
            "Chart data query failed",
            extra={"tenant_id": tenant_id},
            exc_info=exc,
        )

    return chart


def invalidate_tenant_cache(tenant_id: str | None = None) -> None:
    """Clear config cache (call after tenant config updates)."""
    with _cache_lock:
        if tenant_id:
            _tenant_configs.pop(tenant_id, None)
        else:
            _tenant_configs.clear()
