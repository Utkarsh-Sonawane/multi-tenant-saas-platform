"""
app.py — Main Flask application for the Multi-Tenant SaaS Platform.

Routing strategy:
  GET  /                         → Redirect to /login
  GET  /login                    → Login page (tenant switcher)
  POST /login                    → Authenticate (demo auth) → redirect dashboard
  GET  /<tenant_id>              → Redirect to /<tenant_id>/dashboard
  GET  /<tenant_id>/dashboard    → Tenant dashboard
  GET  /<tenant_id>/module/<mod> → Module data page
  GET  /<tenant_id>/api/data     → JSON: table rows (AJAX/pagination)
  GET  /<tenant_id>/api/charts   → JSON: Chart.js datasets
  GET  /<tenant_id>/api/counts   → JSON: record counts per module
  POST /<tenant_id>/logout       → Clear session → redirect /login
  GET  /healthz                  → Liveness probe
  GET  /readyz                   → Readiness probe
  GET  /metrics                  → Prometheus scrape endpoint
"""

import time
import uuid
import os
from functools import wraps

from flask import (
    Flask, g, request, session, redirect, url_for,
    render_template, jsonify, Response, abort,
)
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from config import Config
import db_manager as db
import metrics as prom
from logger import get_logger

# ─── App factory ──────────────────────────────────────────────────────────────

app = Flask(
    __name__,
    template_folder="../frontend/templates",
    static_folder="../frontend/static",
)
app.config.from_object(Config)

log = get_logger("app")

# Demo credentials — in production these come from an IAM / LDAP system
DEMO_USERS = {
    "admin":  "admin123",
    "viewer": "viewer123",
}

# ─── Request lifecycle hooks ──────────────────────────────────────────────────

@app.before_request
def _before():
    g.request_id = str(uuid.uuid4())[:8]
    g.start_time = time.perf_counter()
    g.tenant_id  = "unknown"

    # Extract tenant_id from the first path segment if present
    parts = request.path.strip("/").split("/")
    if parts and parts[0].startswith("tenant-"):
        g.tenant_id = parts[0]

    prom.record_request_start(g.tenant_id, request.method)


@app.after_request
def _after(response: Response) -> Response:
    duration = time.perf_counter() - g.start_time
    endpoint = request.endpoint or request.path

    prom.record_request_end(
        g.tenant_id, request.method, endpoint,
        response.status_code, duration,
    )
    log.info(
        "HTTP request",
        extra={
            "tenant_id":   g.tenant_id,
            "endpoint":    endpoint,
            "method":      request.method,
            "request_id":  g.request_id,
            "status":      response.status_code,
            "duration_ms": round(duration * 1000, 2),
            "environment": Config.ENVIRONMENT,
        },
    )
    response.headers["X-Request-ID"] = g.request_id
    return response


# ─── Auth decorator ───────────────────────────────────────────────────────────

def login_required(f):
    @wraps(f)
    def decorated(*args, **kwargs):
        if "username" not in session or "tenant_id" not in session:
            return redirect(url_for("login"))
        # Ensure the session tenant matches the URL tenant
        tenant_id = kwargs.get("tenant_id")
        if tenant_id and session.get("tenant_id") != tenant_id:
            return redirect(url_for("login"))
        return f(*args, **kwargs)
    return decorated


# ─── Tenant context helper ────────────────────────────────────────────────────

def _load_tenant(tenant_id: str) -> dict:
    """Load tenant config or abort 404."""
    cfg = db.get_tenant_config(tenant_id)
    if not cfg:
        abort(404)
    return cfg


# ─── Public routes ─────────────────────────────────────────────────────────────

@app.route("/")
def index():
    return redirect(url_for("login"))


@app.route("/login", methods=["GET", "POST"])
def login():
    # Fetch all active tenants for the switcher dropdown
    from sqlalchemy import text as sqlt
    from db_manager import ConfigSession
    tenants = []
    try:
        sess = ConfigSession()
        try:
            rows = sess.execute(
                sqlt("SELECT tenant_id, company_name, theme_color "
                     "FROM tenant_config WHERE status='active' ORDER BY id")
            ).mappings().fetchall()
            tenants = [dict(r) for r in rows]
        finally:
            sess.close()
    except Exception:
        pass

    if request.method == "POST":
        tenant_id = request.form.get("tenant_id", "").strip()
        username  = request.form.get("username", "").strip()
        password  = request.form.get("password", "").strip()

        if username not in DEMO_USERS or DEMO_USERS[username] != password:
            return render_template("login.html", tenants=tenants,
                                   error="Invalid username or password.")

        cfg = db.get_tenant_config(tenant_id)
        if not cfg:
            return render_template("login.html", tenants=tenants,
                                   error=f"Tenant '{tenant_id}' not found or inactive.")

        session.permanent = True
        session["username"]  = username
        session["tenant_id"] = tenant_id
        log.info("User logged in", extra={"tenant_id": tenant_id})
        return redirect(url_for("dashboard", tenant_id=tenant_id))

    return render_template("login.html", tenants=tenants, error=None)


@app.route("/<tenant_id>/logout", methods=["POST"])
def logout(tenant_id: str):
    tid = session.pop("tenant_id", "unknown")
    session.pop("username", None)
    log.info("User logged out", extra={"tenant_id": tid})
    return redirect(url_for("login"))


# ─── Tenant routes ─────────────────────────────────────────────────────────────

@app.route("/<tenant_id>")
@login_required
def tenant_root(tenant_id: str):
    return redirect(url_for("dashboard", tenant_id=tenant_id))


@app.route("/<tenant_id>/dashboard")
@login_required
def dashboard(tenant_id: str):
    cfg = _load_tenant(tenant_id)
    modules = cfg.get("modules_enabled", [])

    # Record counts for KPI cards
    counts = db.get_table_counts(tenant_id, cfg["db_name"], modules)
    total_records = sum(counts.values())

    # Primary module data (first module in list)
    primary_module = modules[0] if modules else None
    table_data = {}
    if primary_module:
        table_data = db.fetch_table_data(tenant_id, cfg["db_name"], primary_module, limit=5)

    return render_template(
        "dashboard.html",
        tenant=cfg,
        tenant_id=tenant_id,
        modules=modules,
        counts=counts,
        total_records=total_records,
        primary_module=primary_module,
        table_data=table_data,
        username=session.get("username", "User"),
        pod_name=Config.K8S_POD_NAME,
        namespace=Config.K8S_NAMESPACE,
        environment=Config.ENVIRONMENT,
        region=Config.AWS_REGION,
        active_page="dashboard",
    )


@app.route("/<tenant_id>/module/<module_name>")
@login_required
def module_page(tenant_id: str, module_name: str):
    cfg = _load_tenant(tenant_id)
    modules = cfg.get("modules_enabled", [])

    if module_name not in modules:
        abort(404)

    table_data = db.fetch_table_data(
        tenant_id, cfg["db_name"], module_name,
        limit=int(request.args.get("limit", 10)),
        offset=int(request.args.get("offset", 0)),
        search=request.args.get("search", ""),
    )

    return render_template(
        "module_page.html",
        tenant=cfg,
        tenant_id=tenant_id,
        modules=modules,
        module_name=module_name,
        table_data=table_data,
        username=session.get("username", "User"),
        environment=Config.ENVIRONMENT,
        active_page=module_name,
        limit=int(request.args.get("limit", 10)),
        offset=int(request.args.get("offset", 0)),
        search=request.args.get("search", ""),
    )


# ─── API endpoints (AJAX) ─────────────────────────────────────────────────────

@app.route("/<tenant_id>/api/data")
@login_required
def api_data(tenant_id: str):
    cfg = _load_tenant(tenant_id)
    module = request.args.get("module", "")
    limit  = int(request.args.get("limit", 10))
    offset = int(request.args.get("offset", 0))
    search = request.args.get("search", "")

    result = db.fetch_table_data(tenant_id, cfg["db_name"], module, limit, offset, search)
    # Stringify row values for JSON safety
    for row in result.get("rows", []):
        for k, v in row.items():
            if hasattr(v, "isoformat"):
                row[k] = v.isoformat()
            elif v is None:
                row[k] = ""
    return jsonify(result)


@app.route("/<tenant_id>/api/charts")
@login_required
def api_charts(tenant_id: str):
    cfg     = _load_tenant(tenant_id)
    modules = cfg.get("modules_enabled", [])
    data    = db.get_chart_data(tenant_id, cfg["db_name"], modules)
    return jsonify(data)


@app.route("/<tenant_id>/api/counts")
@login_required
def api_counts(tenant_id: str):
    cfg     = _load_tenant(tenant_id)
    modules = cfg.get("modules_enabled", [])
    counts  = db.get_table_counts(tenant_id, cfg["db_name"], modules)
    return jsonify(counts)


# ─── Infrastructure / Ops endpoints ───────────────────────────────────────────

@app.route("/healthz")
def healthz():
    """Kubernetes liveness probe."""
    return jsonify({"status": "ok", "service": "multi-tenant-saas"}), 200


@app.route("/readyz")
def readyz():
    """Kubernetes readiness probe — verify config_db is reachable."""
    from sqlalchemy import text as sqlt
    from db_manager import _config_engine
    try:
        with _config_engine.connect() as conn:
            conn.execute(sqlt("SELECT 1"))
        return jsonify({"status": "ready"}), 200
    except Exception as e:
        return jsonify({"status": "not_ready", "error": str(e)}), 503


@app.route("/metrics")
def metrics():
    """Prometheus scrape endpoint."""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


# ─── Error handlers ───────────────────────────────────────────────────────────

@app.errorhandler(404)
def not_found(e):
    tenant_id = getattr(g, "tenant_id", None)
    if tenant_id and tenant_id != "unknown":
        cfg     = db.get_tenant_config(tenant_id)
        modules = cfg.get("modules_enabled", []) if cfg else []
        return render_template("404.html", tenant=cfg, tenant_id=tenant_id,
                               modules=modules), 404
    return render_template("404.html", tenant=None, tenant_id=None, modules=[]), 404


@app.errorhandler(500)
def server_error(e):
    tenant_id = getattr(g, "tenant_id", None)
    if tenant_id and tenant_id != "unknown":
        cfg     = db.get_tenant_config(tenant_id)
        modules = cfg.get("modules_enabled", []) if cfg else []
        return render_template("500.html", tenant=cfg, tenant_id=tenant_id,
                               modules=modules), 500
    return render_template("500.html", tenant=None, tenant_id=None, modules=[]), 500


# ─── Entry point ──────────────────────────────────────────────────────────────

if __name__ == "__main__":
    app.run(
        host="0.0.0.0",
        port=int(os.getenv("PORT", "5000")),
        debug=Config.DEBUG,
    )
