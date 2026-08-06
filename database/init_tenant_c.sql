-- ============================================================
-- FILE: init_tenant_c.sql
-- DATABASE: tenant_c_db
-- TENANT: PQR School (Tenant C)
-- ============================================================

-- CREATE DATABASE tenant_c_db;
-- \c tenant_c_db;

DROP TABLE IF EXISTS attendance CASCADE;
DROP TABLE IF EXISTS students CASCADE;
DROP TABLE IF EXISTS teachers CASCADE;

-- ============================================================
-- TABLE: teachers
-- ============================================================
CREATE TABLE teachers (
    id              SERIAL PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    employee_id     VARCHAR(50)   NOT NULL UNIQUE,
    subject         VARCHAR(100)  NOT NULL,
    department      VARCHAR(100)  NOT NULL,
    qualification   VARCHAR(150),
    experience_yrs  INTEGER       NOT NULL DEFAULT 0,
    status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'on_leave', 'retired')),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: students
-- ============================================================
CREATE TABLE students (
    id              SERIAL PRIMARY KEY,
    first_name      VARCHAR(100)  NOT NULL,
    last_name       VARCHAR(100)  NOT NULL,
    roll_number     VARCHAR(30)   NOT NULL UNIQUE,
    class_grade     VARCHAR(20)   NOT NULL,
    section         VARCHAR(5)    NOT NULL,
    date_of_birth   DATE          NOT NULL,
    gender          VARCHAR(10)   NOT NULL CHECK (gender IN ('Male','Female','Other')),
    parent_name     VARCHAR(200),
    parent_phone    VARCHAR(30),
    city            VARCHAR(100),
    status          VARCHAR(20)   NOT NULL DEFAULT 'active'
                      CHECK (status IN ('active', 'transferred', 'graduated', 'withdrawn')),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: attendance
-- ============================================================
CREATE TABLE attendance (
    id              SERIAL PRIMARY KEY,
    student_id      INTEGER       NOT NULL REFERENCES students(id),
    attendance_date DATE          NOT NULL,
    status          VARCHAR(15)   NOT NULL DEFAULT 'present'
                      CHECK (status IN ('present','absent','late','excused')),
    marked_by       INTEGER       REFERENCES teachers(id),
    remarks         VARCHAR(200),
    created_at      TIMESTAMP     NOT NULL DEFAULT NOW(),
    UNIQUE (student_id, attendance_date)
);

-- ============================================================
-- SEED: teachers
-- ============================================================
INSERT INTO teachers (first_name, last_name, employee_id, subject, department, qualification, experience_yrs, status) VALUES
('Ramesh',     'Trivedi',   'EMP-2024-001', 'Mathematics',          'Science',          'M.Sc Mathematics',   18, 'active'),
('Saraswati',  'Naidu',     'EMP-2024-002', 'English Literature',   'Languages',        'M.A English',        12, 'active'),
('Girish',     'Tiwari',    'EMP-2024-003', 'Physics',              'Science',          'M.Sc Physics',       15, 'active'),
('Lalitha',    'Srinivas',  'EMP-2024-004', 'Chemistry',            'Science',          'M.Sc Chemistry',     10, 'active'),
('Mohan',      'Chatterjee','EMP-2024-005', 'History',              'Social Studies',   'M.A History',        8,  'active'),
('Sudha',      'Varma',     'EMP-2024-006', 'Geography',            'Social Studies',   'M.A Geography',      6,  'active'),
('Venkat',     'Rao',       'EMP-2024-007', 'Computer Science',     'Technology',       'M.Tech CS',          9,  'active'),
('Nalini',     'Bhatt',     'EMP-2024-008', 'Biology',              'Science',          'M.Sc Biology',       11, 'on_leave'),
('Ravi',       'Shankar',   'EMP-2024-009', 'Physical Education',   'Sports',           'B.P.Ed',             5,  'active'),
('Kamala',     'Murthy',    'EMP-2024-010', 'Hindi',                'Languages',        'M.A Hindi',          20, 'active');

-- ============================================================
-- SEED: students
-- ============================================================
INSERT INTO students (first_name, last_name, roll_number, class_grade, section, date_of_birth, gender, parent_name, parent_phone, city, status) VALUES
('Aarav',     'Sharma',    'PQR-2024-001', 'Grade 10', 'A', '2009-04-15', 'Male',   'Rajesh Sharma',   '+91-9200001111', 'Mumbai',    'active'),
('Ananya',    'Verma',     'PQR-2024-002', 'Grade 10', 'A', '2009-08-22', 'Female', 'Sunil Verma',     '+91-9200002222', 'Delhi',     'active'),
('Kabir',     'Singh',     'PQR-2024-003', 'Grade 10', 'B', '2009-01-10', 'Male',   'Hardip Singh',    '+91-9200003333', 'Chandigarh','active'),
('Diya',      'Patel',     'PQR-2024-004', 'Grade 9',  'A', '2010-06-30', 'Female', 'Arvind Patel',    '+91-9200004444', 'Ahmedabad', 'active'),
('Ishaan',    'Kumar',     'PQR-2024-005', 'Grade 9',  'B', '2010-11-18', 'Male',   'Suresh Kumar',    '+91-9200005555', 'Bangalore', 'active'),
('Prisha',    'Nair',      'PQR-2024-006', 'Grade 8',  'A', '2011-03-05', 'Female', 'Radhika Nair',    '+91-9200006666', 'Kochi',     'active'),
('Vihaan',    'Gupta',     'PQR-2024-007', 'Grade 8',  'B', '2011-09-20', 'Male',   'Alok Gupta',      '+91-9200007777', 'Lucknow',   'active'),
('Aisha',     'Joshi',     'PQR-2024-008', 'Grade 7',  'A', '2012-02-14', 'Female', 'Mahesh Joshi',    '+91-9200008888', 'Pune',      'active'),
('Rohan',     'Reddy',     'PQR-2024-009', 'Grade 7',  'B', '2012-07-08', 'Male',   'Chandra Reddy',   '+91-9200009999', 'Hyderabad', 'active'),
('Myra',      'Pillai',    'PQR-2024-010', 'Grade 6',  'A', '2013-12-25', 'Female', 'Krishnan Pillai', '+91-9200010000', 'Chennai',   'active');

-- ============================================================
-- SEED: attendance (last 5 days for each student)
-- ============================================================
DO $$
DECLARE
    s_id    INTEGER;
    t_id    INTEGER := 1;
    d       INTEGER;
    att_status VARCHAR(15);
BEGIN
    FOR s_id IN 1..10 LOOP
        FOR d IN 1..5 LOOP
            -- Randomly assign attendance (mostly present)
            att_status := CASE
                WHEN random() < 0.85 THEN 'present'
                WHEN random() < 0.50 THEN 'absent'
                WHEN random() < 0.50 THEN 'late'
                ELSE 'excused'
            END;
            INSERT INTO attendance (student_id, attendance_date, status, marked_by)
            VALUES (s_id, CURRENT_DATE - d, att_status, ((s_id - 1) % 10) + 1)
            ON CONFLICT (student_id, attendance_date) DO NOTHING;
        END LOOP;
    END LOOP;
END $$;

-- Indexes
CREATE INDEX idx_attendance_student  ON attendance(student_id);
CREATE INDEX idx_attendance_date     ON attendance(attendance_date);
CREATE INDEX idx_attendance_status   ON attendance(status);
CREATE INDEX idx_students_class      ON students(class_grade);
CREATE INDEX idx_students_roll       ON students(roll_number);

-- Verify
SELECT 'teachers'   AS tbl, COUNT(*) AS rows FROM teachers
UNION ALL
SELECT 'students'   AS tbl, COUNT(*) AS rows FROM students
UNION ALL
SELECT 'attendance' AS tbl, COUNT(*) AS rows FROM attendance;
