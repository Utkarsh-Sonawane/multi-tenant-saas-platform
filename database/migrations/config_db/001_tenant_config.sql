CREATE TABLE IF NOT EXISTS tenant_config (
  id serial PRIMARY KEY, tenant_id varchar(50) UNIQUE NOT NULL, tenant_name varchar(100) NOT NULL,
  company_name varchar(150) NOT NULL, theme_color varchar(20) NOT NULL, company_logo varchar(255),
  db_host varchar(255) NOT NULL, db_port integer NOT NULL DEFAULT 5432, db_name varchar(100) NOT NULL,
  db_username varchar(100) NOT NULL, namespace varchar(100) NOT NULL, service_name varchar(100) NOT NULL,
  ingress_path varchar(100) NOT NULL, status varchar(20) NOT NULL DEFAULT 'active',
  modules_enabled text[] NOT NULL DEFAULT '{}', created_at timestamptz NOT NULL DEFAULT now(), updated_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_tenant_config_status ON tenant_config(status);
INSERT INTO tenant_config (tenant_id,tenant_name,company_name,theme_color,db_host,db_name,db_username,namespace,service_name,ingress_path,modules_enabled)
VALUES
('tenant-a','Tenant A','ABC Retail','#0d6efd','managed-by-kubernetes','tenant_a_db','tenant_a_user','tenant-a','tenant-a-service','/tenant-a',ARRAY['Products','Orders','Customers']),
('tenant-b','Tenant B','XYZ Hospital','#198754','managed-by-kubernetes','tenant_b_db','tenant_b_user','tenant-b','tenant-b-service','/tenant-b',ARRAY['Patients','Doctors','Appointments']),
('tenant-c','Tenant C','PQR School','#fd7e14','managed-by-kubernetes','tenant_c_db','tenant_c_user','tenant-c','tenant-c-service','/tenant-c',ARRAY['Students','Teachers','Attendance'])
ON CONFLICT (tenant_id) DO NOTHING;
