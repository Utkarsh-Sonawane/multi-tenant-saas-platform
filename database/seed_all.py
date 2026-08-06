#!/usr/bin/env python3
"""
seed_all.py — Local development DB seeder.
Creates all databases and runs all init SQL scripts against a local PostgreSQL server.

Usage:
    python seed_all.py

Environment Variables:
    POSTGRES_HOST      (default: localhost)
    POSTGRES_PORT      (default: 5432)
    POSTGRES_USER      (default: postgres)
    POSTGRES_PASSWORD  (default: postgres)
"""

import os
import sys
import psycopg2
from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT

HOST     = os.getenv("POSTGRES_HOST",     "localhost")
PORT     = int(os.getenv("POSTGRES_PORT", "5432"))
USER     = os.getenv("POSTGRES_USER",     "postgres")
PASSWORD = os.getenv("POSTGRES_PASSWORD", "postgres")

DATABASES = ["config_db", "tenant_a_db", "tenant_b_db", "tenant_c_db"]
SQL_FILES = {
    "config_db":   "init_config_db.sql",
    "tenant_a_db": "init_tenant_a.sql",
    "tenant_b_db": "init_tenant_b.sql",
    "tenant_c_db": "init_tenant_c.sql",
}

def create_database(admin_conn, db_name: str):
    """Create database if not exists."""
    with admin_conn.cursor() as cur:
        cur.execute("SELECT 1 FROM pg_database WHERE datname = %s", (db_name,))
        if cur.fetchone():
            print(f"  [SKIP] Database '{db_name}' already exists.")
        else:
            cur.execute(f'CREATE DATABASE "{db_name}"')
            print(f"  [OK]   Database '{db_name}' created.")

def run_sql_file(db_name: str, sql_file: str):
    """Connect to the given database and execute the SQL file."""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    sql_path   = os.path.join(script_dir, sql_file)

    if not os.path.exists(sql_path):
        print(f"  [WARN] SQL file not found: {sql_path}")
        return

    conn = psycopg2.connect(
        host=HOST, port=PORT, dbname=db_name,
        user=USER, password=PASSWORD
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)

    with open(sql_path, "r", encoding="utf-8") as f:
        sql = f.read()

    # Remove placeholder comments for init scripts
    sql_lines = [
        line for line in sql.splitlines()
        if not line.strip().startswith("-- CREATE DATABASE")
        and not line.strip().startswith("-- \\c")
    ]
    sql = "\n".join(sql_lines)

    try:
        with conn.cursor() as cur:
            cur.execute(sql)
        print(f"  [OK]   Executed '{sql_file}' on '{db_name}'")
    except Exception as e:
        print(f"  [ERR]  Failed on '{db_name}': {e}", file=sys.stderr)
    finally:
        conn.close()

def main():
    print("=" * 60)
    print("  Multi-Tenant SaaS Platform — Database Seeder")
    print("=" * 60)
    print(f"\nConnecting to PostgreSQL at {HOST}:{PORT} as '{USER}'...\n")

    # Admin connection to create databases
    try:
        admin_conn = psycopg2.connect(
            host=HOST, port=PORT, dbname="postgres",
            user=USER, password=PASSWORD
        )
        admin_conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    except Exception as e:
        print(f"[FATAL] Cannot connect to PostgreSQL: {e}", file=sys.stderr)
        sys.exit(1)

    print("Step 1: Creating databases...")
    for db in DATABASES:
        create_database(admin_conn, db)
    admin_conn.close()

    print("\nStep 2: Running init SQL scripts...")
    for db_name, sql_file in SQL_FILES.items():
        run_sql_file(db_name, sql_file)

    print("\n" + "=" * 60)
    print("  All databases initialized successfully!")
    print("=" * 60)

if __name__ == "__main__":
    main()
