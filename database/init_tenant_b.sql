-- ============================================================
-- FILE: init_tenant_b.sql
-- DATABASE: tenant_b_db
-- TENANT: XYZ Hospital (Tenant B)
-- ============================================================

-- CREATE DATABASE tenant_b_db;
-- \c tenant_b_db;

DROP TABLE IF EXISTS appointments CASCADE;
DROP TABLE IF EXISTS patients CASCADE;
DROP TABLE IF EXISTS doctors CASCADE;

-- ============================================================
-- TABLE: doctors
-- ============================================================
CREATE TABLE doctors (
    id              SERIAL PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    specialization  VARCHAR(150)  NOT NULL,
    license_no      VARCHAR(50)   NOT NULL UNIQUE,
    department      VARCHAR(100)  NOT NULL,
    experience_yrs  INTEGER       NOT NULL DEFAULT 0,
    status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'on_leave', 'inactive')),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: patients
-- ============================================================
CREATE TABLE patients (
    id              SERIAL PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    date_of_birth   DATE          NOT NULL,
    gender          VARCHAR(10)   NOT NULL CHECK (gender IN ('Male','Female','Other')),
    blood_group     VARCHAR(5),
    phone           VARCHAR(30),
    email           VARCHAR(200),
    city            VARCHAR(100),
    status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'discharged', 'critical')),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: appointments
-- ============================================================
CREATE TABLE appointments (
    id                SERIAL PRIMARY KEY,
    patient_id        INTEGER       NOT NULL REFERENCES patients(id),
    doctor_id         INTEGER       NOT NULL REFERENCES doctors(id),
    appointment_date  DATE          NOT NULL,
    appointment_time  TIME          NOT NULL,
    reason            VARCHAR(300),
    status            VARCHAR(30)   NOT NULL DEFAULT 'scheduled'
                        CHECK (status IN ('scheduled','in_progress','completed','cancelled','no_show')),
    notes             TEXT,
    created_at        TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEED: doctors
-- ============================================================
INSERT INTO doctors (first_name, last_name, specialization, license_no, department, experience_yrs, status) VALUES
('Dr. Anita',   'Desai',    'Cardiologist',          'MCI-2024-001', 'Cardiology',      15, 'active'),
('Dr. Rajesh',  'Mehta',    'Orthopedic Surgeon',    'MCI-2024-002', 'Orthopedics',     12, 'active'),
('Dr. Sunita',  'Iyer',     'Pediatrician',          'MCI-2024-003', 'Pediatrics',      10, 'active'),
('Dr. Vivek',   'Khanna',   'Neurologist',           'MCI-2024-004', 'Neurology',       18, 'active'),
('Dr. Pooja',   'Agarwal',  'Dermatologist',         'MCI-2024-005', 'Dermatology',     8,  'active'),
('Dr. Suresh',  'Nair',     'General Surgeon',       'MCI-2024-006', 'Surgery',         20, 'active'),
('Dr. Kavitha', 'Rao',      'Gynecologist',          'MCI-2024-007', 'Gynecology',      14, 'active'),
('Dr. Arjun',   'Bose',     'Radiologist',           'MCI-2024-008', 'Radiology',       9,  'active'),
('Dr. Priya',   'Malhotra', 'Endocrinologist',       'MCI-2024-009', 'Endocrinology',   11, 'on_leave'),
('Dr. Nikhil',  'Shah',     'Emergency Physician',   'MCI-2024-010', 'Emergency',       7,  'active');

-- ============================================================
-- SEED: patients
-- ============================================================
INSERT INTO patients (first_name, last_name, date_of_birth, gender, blood_group, phone, email, city, status) VALUES
('Mohan',     'Das',       '1975-03-12', 'Male',   'O+',  '+91-9100001111', 'mohan.das@mail.com',    'Mumbai',    'active'),
('Lakshmi',   'Rao',       '1985-07-22', 'Female', 'A+',  '+91-9100002222', 'lakshmi.rao@mail.com',  'Chennai',   'active'),
('Ranjit',    'Kumar',     '1990-11-05', 'Male',   'B+',  '+91-9100003333', 'ranjit.k@mail.com',     'Delhi',     'active'),
('Savita',    'Bendre',    '1968-02-18', 'Female', 'AB+', '+91-9100004444', 'savita.b@mail.com',     'Pune',      'active'),
('Arjun',     'Pillai',    '1995-06-30', 'Male',   'O-',  '+91-9100005555', 'arjun.p@mail.com',      'Kochi',     'critical'),
('Deepa',     'Sharma',    '1980-09-14', 'Female', 'A-',  '+91-9100006666', 'deepa.s@mail.com',      'Jaipur',    'active'),
('Vinod',     'Patel',     '1972-12-28', 'Male',   'B-',  '+91-9100007777', 'vinod.p@mail.com',      'Ahmedabad', 'discharged'),
('Geetha',    'Krishnan',  '1988-04-07', 'Female', 'AB-', '+91-9100008888', 'geetha.k@mail.com',     'Bangalore', 'active'),
('Suresh',    'Yadav',     '1963-08-21', 'Male',   'O+',  '+91-9100009999', 'suresh.y@mail.com',     'Lucknow',   'active'),
('Meera',     'Joshi',     '1998-01-15', 'Female', 'A+',  '+91-9100010000', 'meera.j@mail.com',      'Nagpur',    'active');

-- ============================================================
-- SEED: appointments
-- ============================================================
INSERT INTO appointments (patient_id, doctor_id, appointment_date, appointment_time, reason, status, notes) VALUES
(1,  1, CURRENT_DATE - 20, '10:00', 'Chest pain evaluation',        'completed',  'Prescribed ECG & medication'),
(2,  3, CURRENT_DATE - 15, '11:30', 'Routine child vaccination',    'completed',  'All vaccines up to date'),
(3,  2, CURRENT_DATE - 10, '09:00', 'Knee pain follow-up',          'completed',  'Physiotherapy recommended'),
(4,  7, CURRENT_DATE - 5,  '14:00', 'Routine gynecology checkup',   'completed',  'No abnormalities found'),
(5,  4, CURRENT_DATE - 3,  '08:30', 'Migraine treatment',           'in_progress','MRI scan ordered'),
(6,  5, CURRENT_DATE - 1,  '16:00', 'Skin rash diagnosis',          'scheduled',  NULL),
(7,  6, CURRENT_DATE,      '10:30', 'Appendix pain consultation',   'scheduled',  NULL),
(8,  9, CURRENT_DATE + 1,  '13:00', 'Diabetes management',          'scheduled',  NULL),
(9,  1, CURRENT_DATE + 2,  '11:00', 'Blood pressure monitoring',    'scheduled',  NULL),
(10, 3, CURRENT_DATE + 3,  '15:30', 'Fever and cold treatment',     'scheduled',  NULL),
(1,  10,CURRENT_DATE - 7,  '09:30', 'Emergency - High fever',       'completed',  'IV antibiotics administered'),
(3,  4, CURRENT_DATE - 12, '14:30', 'Acne treatment',               'completed',  'Topical medication prescribed'),
(6,  2, CURRENT_DATE + 5,  '10:00', 'Back pain consultation',       'scheduled',  NULL),
(8,  8, CURRENT_DATE - 8,  '12:00', 'X-ray review',                 'completed',  'No fractures detected'),
(5,  6, CURRENT_DATE - 25, '08:00', 'Appendectomy follow-up',       'completed',  'Recovery progressing well');

-- Indexes
CREATE INDEX idx_appointments_patient  ON appointments(patient_id);
CREATE INDEX idx_appointments_doctor   ON appointments(doctor_id);
CREATE INDEX idx_appointments_date     ON appointments(appointment_date);
CREATE INDEX idx_appointments_status   ON appointments(status);

-- Verify
SELECT 'doctors'       AS tbl, COUNT(*) AS rows FROM doctors
UNION ALL
SELECT 'patients'      AS tbl, COUNT(*) AS rows FROM patients
UNION ALL
SELECT 'appointments'  AS tbl, COUNT(*) AS rows FROM appointments;
