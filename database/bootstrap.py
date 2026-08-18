#!/usr/bin/env python3
"""Idempotently provision tenant databases and apply versioned migrations.

Run only from the in-VPC Kubernetes bootstrap Job.  It requires the RDS master
credential; normal application Pods must never receive that credential.
"""
from __future__ import annotations

import os
import re
from pathlib import Path

import psycopg2
from psycopg2 import sql

IDENTIFIER = re.compile(r"^[a-z][a-z0-9_]{0,62}$")
ROOT = Path(__file__).parent / "migrations"


def required(name: str) -> str:
    value = os.getenv(name)
    if not value:
        raise RuntimeError(f"Required environment variable {name} is missing")
    return value


def identifier(value: str) -> str:
    if not IDENTIFIER.fullmatch(value):
        raise RuntimeError(f"Unsafe PostgreSQL identifier: {value!r}")
    return value


def connect(database: str, user: str, password: str):
    return psycopg2.connect(
        host=required("RDS_HOST"), port=int(os.getenv("RDS_PORT", "5432")),
        dbname=identifier(database), user=user, password=password,
        connect_timeout=10,
    )


def ensure_role(conn, role: str, password: str) -> None:
    role = identifier(role)
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_roles WHERE rolname = %s", (role,))
        if not cur.fetchone():
            cur.execute(sql.SQL("CREATE ROLE {} LOGIN").format(sql.Identifier(role)))
        cur.execute(sql.SQL("ALTER ROLE {} PASSWORD %s").format(sql.Identifier(role)), (password,))


def ensure_database(conn, database: str, owner: str) -> None:
    database, owner = identifier(database), identifier(owner)
    with conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (database,))
        if not cur.fetchone():
            cur.execute(sql.SQL("CREATE DATABASE {} OWNER {}").format(
                sql.Identifier(database), sql.Identifier(owner)
            ))
        cur.execute(sql.SQL("REVOKE ALL ON DATABASE {} FROM PUBLIC").format(sql.Identifier(database)))
        cur.execute(sql.SQL("GRANT CONNECT ON DATABASE {} TO {}").format(
            sql.Identifier(database), sql.Identifier(owner)
        ))


def apply_migrations(database: str, user: str, password: str) -> None:
    conn = connect(database, user, password)
    try:
        with conn.cursor() as cur:
            cur.execute("CREATE TABLE IF NOT EXISTS schema_migrations (version text PRIMARY KEY, applied_at timestamptz NOT NULL DEFAULT now())")
        conn.commit()
        migration_dir = ROOT / database
        for migration in sorted(migration_dir.glob("*.sql")):
            version = migration.name.split("_", 1)[0]
            with conn.cursor() as cur:
                cur.execute("SELECT 1 FROM schema_migrations WHERE version = %s", (version,))
                if cur.fetchone():
                    continue
                cur.execute(migration.read_text(encoding="utf-8"))
                cur.execute("INSERT INTO schema_migrations (version) VALUES (%s)", (version,))
            conn.commit()
            print(f"Applied {database}/{migration.name}")
    finally:
        conn.close()


def main() -> None:
    master_user, master_password = required("RDS_MASTER_USER"), required("RDS_MASTER_PASSWORD")
    databases = {
        "config_db": ("config_user", required("CONFIG_DB_PASSWORD")),
        "tenant_a_db": ("tenant_a_user", required("TENANT_A_DB_PASSWORD")),
        "tenant_b_db": ("tenant_b_user", required("TENANT_B_DB_PASSWORD")),
        "tenant_c_db": ("tenant_c_user", required("TENANT_C_DB_PASSWORD")),
    }
    admin = connect("postgres", master_user, master_password)
    admin.autocommit = True  # CREATE DATABASE cannot run inside a transaction.
    try:
        for database, (user, password) in databases.items():
            ensure_role(admin, user, password)
            ensure_database(admin, database, user)
    finally:
        admin.close()
    for database, (user, password) in databases.items():
        apply_migrations(database, user, password)
    print("Database bootstrap completed successfully")


if __name__ == "__main__":
    main()
