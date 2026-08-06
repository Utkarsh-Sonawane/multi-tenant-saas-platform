"""
metrics.py — Prometheus metrics for the multi-tenant SaaS platform.

Exposes:
  - http_requests_total          (Counter)   per tenant, method, endpoint, status_code
  - http_request_duration_seconds (Histogram) per tenant, endpoint
  - db_connections_active        (Gauge)     per tenant database
  - db_query_duration_seconds    (Histogram) per tenant, query_type
  - tenant_active                (Gauge)     per tenant_id (1=active, 0=inactive)
"""

from prometheus_client import Counter, Gauge, Histogram, CollectorRegistry, REGISTRY

# ─── HTTP Metrics ──────────────────────────────────────────────────────────────

HTTP_REQUESTS_TOTAL = Counter(
    name="http_requests_total",
    documentation="Total number of HTTP requests",
    labelnames=["tenant_id", "method", "endpoint", "status_code"],
)

HTTP_REQUEST_DURATION = Histogram(
    name="http_request_duration_seconds",
    documentation="HTTP request latency in seconds",
    labelnames=["tenant_id", "endpoint"],
    buckets=[0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1.0, 2.5, 5.0],
)

HTTP_REQUESTS_IN_PROGRESS = Gauge(
    name="http_requests_in_progress",
    documentation="Number of HTTP requests currently in progress",
    labelnames=["tenant_id", "method"],
)

# ─── Database Metrics ──────────────────────────────────────────────────────────

DB_CONNECTIONS_ACTIVE = Gauge(
    name="db_connections_active",
    documentation="Number of active database connections per tenant",
    labelnames=["tenant_id", "db_name"],
)

DB_QUERY_DURATION = Histogram(
    name="db_query_duration_seconds",
    documentation="Database query latency in seconds",
    labelnames=["tenant_id", "query_type"],
    buckets=[0.001, 0.005, 0.01, 0.05, 0.1, 0.5, 1.0],
)

# ─── Tenant Metrics ────────────────────────────────────────────────────────────

TENANT_ACTIVE = Gauge(
    name="tenant_active",
    documentation="Whether a tenant is currently active (1=active, 0=inactive)",
    labelnames=["tenant_id", "company_name"],
)

TENANT_CONFIG_LOADS = Counter(
    name="tenant_config_loads_total",
    documentation="Total number of tenant config loads from config_db",
    labelnames=["tenant_id", "result"],   # result: hit / miss / error
)


def record_request_start(tenant_id: str, method: str) -> None:
    HTTP_REQUESTS_IN_PROGRESS.labels(tenant_id=tenant_id, method=method).inc()


def record_request_end(
    tenant_id: str,
    method: str,
    endpoint: str,
    status_code: int,
    duration: float,
) -> None:
    HTTP_REQUESTS_IN_PROGRESS.labels(tenant_id=tenant_id, method=method).dec()
    HTTP_REQUESTS_TOTAL.labels(
        tenant_id=tenant_id,
        method=method,
        endpoint=endpoint,
        status_code=str(status_code),
    ).inc()
    HTTP_REQUEST_DURATION.labels(
        tenant_id=tenant_id,
        endpoint=endpoint,
    ).observe(duration)


def set_db_connections(tenant_id: str, db_name: str, count: int) -> None:
    DB_CONNECTIONS_ACTIVE.labels(tenant_id=tenant_id, db_name=db_name).set(count)


def record_db_query(tenant_id: str, query_type: str, duration: float) -> None:
    DB_QUERY_DURATION.labels(tenant_id=tenant_id, query_type=query_type).observe(duration)


def mark_tenant_active(tenant_id: str, company_name: str, is_active: bool) -> None:
    TENANT_ACTIVE.labels(tenant_id=tenant_id, company_name=company_name).set(
        1 if is_active else 0
    )
