-- ============================================================
-- FILE: init_config_db.sql
-- PURPOSE: Initialize config_db with tenant_config table
--          and seed all three tenant configurations.
-- ============================================================

-- Create database (run as superuser / admin)
-- CREATE DATABASE config_db;
-- \c config_db;

-- Drop table if re-initializing
DROP TABLE IF EXISTS tenant_config;

-- ============================================================
-- TABLE: tenant_config
-- ============================================================
CREATE TABLE tenant_config (
    id               SERIAL PRIMARY KEY,
    tenant_id        VARCHAR(50)  NOT NULL UNIQUE,
    tenant_name      VARCHAR(100) NOT NULL,
    company_name     VARCHAR(150) NOT NULL,
    theme_color      VARCHAR(20)  NOT NULL DEFAULT '#0d6efd',
    company_logo     VARCHAR(255),
    db_host          VARCHAR(255) NOT NULL,
    db_port          INTEGER      NOT NULL DEFAULT 5432,
    db_name          VARCHAR(100) NOT NULL,
    db_username      VARCHAR(100) NOT NULL,
    namespace        VARCHAR(100) NOT NULL,
    service_name     VARCHAR(100) NOT NULL,
    ingress_path     VARCHAR(100) NOT NULL,
    status           VARCHAR(20)  NOT NULL DEFAULT 'active'
                       CHECK (status IN ('active', 'inactive', 'suspended')),
    modules_enabled  TEXT[]       NOT NULL DEFAULT '{}',
    created_at       TIMESTAMP    NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMP    NOT NULL DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_tenant_config_tenant_id ON tenant_config(tenant_id);
CREATE INDEX idx_tenant_config_status    ON tenant_config(status);

-- ============================================================
-- TENANT A: ABC Retail  (Blue Theme)
-- ============================================================
INSERT INTO tenant_config (
    tenant_id,
    tenant_name,
    company_name,
    theme_color,
    company_logo,
    db_host,
    db_port,
    db_name,
    db_username,
    namespace,
    service_name,
    ingress_path,
    status,
    modules_enabled
) VALUES (
    'tenant-a',
    'Tenant A',
    'ABC Retail',
    '#0d6efd',
    '/static/logos/abc_retail.png',
    '${TENANT_A_DB_HOST}',    -- Replace with RDS endpoint at deploy time
    5432,
    'tenant_a_db',
    'tenant_a_user',
    'tenant-a',
    'tenant-a-service',
    '/tenant-a',
    'active',
    ARRAY['Products', 'Orders', 'Customers']
);

-- ============================================================
-- TENANT B: XYZ Hospital  (Green Theme)
-- ============================================================
INSERT INTO tenant_config (
    tenant_id,
    tenant_name,
    company_name,
    theme_color,
    company_logo,
    db_host,
    db_port,
    db_name,
    db_username,
    namespace,
    service_name,
    ingress_path,
    status,
    modules_enabled
) VALUES (
    'tenant-b',
    'Tenant B',
    'XYZ Hospital',
    '#198754',
    '/static/logos/xyz_hospital.png',
    '${TENANT_B_DB_HOST}',
    5432,
    'tenant_b_db',
    'tenant_b_user',
    'tenant-b',
    'tenant-b-service',
    '/tenant-b',
    'active',
    ARRAY['Patients', 'Doctors', 'Appointments']
);

-- ============================================================
-- TENANT C: PQR School  (Orange Theme)
-- ============================================================
INSERT INTO tenant_config (
    tenant_id,
    tenant_name,
    company_name,
    theme_color,
    company_logo,
    db_host,
    db_port,
    db_name,
    db_username,
    namespace,
    service_name,
    ingress_path,
    status,
    modules_enabled
) VALUES (
    'tenant-c',
    'Tenant C',
    'PQR School',
    '#fd7e14',
    '/static/logos/pqr_school.png',
    '${TENANT_C_DB_HOST}',
    5432,
    'tenant_c_db',
    'tenant_c_user',
    'tenant-c',
    'tenant-c-service',
    '/tenant-c',
    'active',
    ARRAY['Students', 'Teachers', 'Attendance']
);

-- ============================================================
-- Verify
-- ============================================================
SELECT
    tenant_id,
    company_name,
    theme_color,
    db_name,
    namespace,
    status,
    modules_enabled
FROM tenant_config
ORDER BY id;
