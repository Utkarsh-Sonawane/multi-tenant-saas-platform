-- ============================================================
-- FILE: init_tenant_a.sql
-- DATABASE: tenant_a_db
-- TENANT: ABC Retail (Tenant A)
-- ============================================================

-- CREATE DATABASE tenant_a_db;
-- \c tenant_a_db;

-- ============================================================
-- TABLE: products
-- ============================================================
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS products CASCADE;

CREATE TABLE products (
    id           SERIAL PRIMARY KEY,
    name         VARCHAR(200)   NOT NULL,
    category     VARCHAR(100)   NOT NULL,
    sku          VARCHAR(50)    NOT NULL UNIQUE,
    price        NUMERIC(10,2)  NOT NULL,
    stock_qty    INTEGER        NOT NULL DEFAULT 0,
    status       VARCHAR(20)    NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active', 'inactive', 'out_of_stock')),
    created_at   TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: customers
-- ============================================================
CREATE TABLE customers (
    id           SERIAL PRIMARY KEY,
    first_name   VARCHAR(100)   NOT NULL,
    last_name    VARCHAR(100)   NOT NULL,
    email        VARCHAR(200)   NOT NULL UNIQUE,
    phone        VARCHAR(30),
    city         VARCHAR(100),
    status       VARCHAR(20)    NOT NULL DEFAULT 'active'
                   CHECK (status IN ('active', 'inactive')),
    created_at   TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ============================================================
-- TABLE: orders
-- ============================================================
CREATE TABLE orders (
    id             SERIAL PRIMARY KEY,
    customer_id    INTEGER        NOT NULL REFERENCES customers(id),
    product_id     INTEGER        NOT NULL REFERENCES products(id),
    quantity       INTEGER        NOT NULL DEFAULT 1,
    total_price    NUMERIC(10,2)  NOT NULL,
    order_status   VARCHAR(30)    NOT NULL DEFAULT 'pending'
                     CHECK (order_status IN ('pending','processing','shipped','delivered','cancelled')),
    order_date     TIMESTAMP      NOT NULL DEFAULT NOW()
);

-- ============================================================
-- SEED: products
-- ============================================================
INSERT INTO products (name, category, sku, price, stock_qty, status) VALUES
('Apple iPhone 15 Pro',    'Electronics',  'ELEC-001', 129999.00, 45,  'active'),
('Samsung Galaxy S24',     'Electronics',  'ELEC-002',  89999.00, 30,  'active'),
('Sony 55" OLED TV',       'Electronics',  'ELEC-003', 179999.00, 12,  'active'),
('Nike Air Max 2024',      'Footwear',     'FOOT-001',   9999.00, 120, 'active'),
('Adidas Ultraboost 23',   'Footwear',     'FOOT-002',   8499.00, 80,  'active'),
('Levi''s 501 Original',   'Clothing',     'CLTH-001',   4999.00, 200, 'active'),
('Allen Solly Formal Shirt','Clothing',    'CLTH-002',   2499.00, 150, 'active'),
('Bosch Cordless Drill',   'Tools',        'TOOL-001',  12999.00, 25,  'active'),
('Prestige Pressure Cooker','Kitchen',     'KTCH-001',   3499.00, 60,  'active'),
('IKEA Study Table',       'Furniture',    'FURN-001',  15999.00, 18,  'active'),
('Canon DSLR EOS 1500D',   'Electronics',  'ELEC-004',  49999.00, 8,   'active'),
('HP Pavilion Laptop',     'Electronics',  'ELEC-005',  69999.00, 22,  'active'),
('Wilson Tennis Racket',   'Sports',       'SPRT-001',   6999.00, 35,  'active'),
('Casio Digital Watch',    'Accessories',  'ACCR-001',   2999.00, 90,  'active'),
('Nestlé KitKat Bulk Pack','Grocery',      'GROC-001',    599.00, 500, 'active');

-- ============================================================
-- SEED: customers
-- ============================================================
INSERT INTO customers (first_name, last_name, email, phone, city, status) VALUES
('Rahul',    'Sharma',     'rahul.sharma@email.com',     '+91-9001112222', 'Mumbai',    'active'),
('Priya',    'Verma',      'priya.verma@email.com',      '+91-9003334444', 'Delhi',     'active'),
('Arun',     'Kumar',      'arun.kumar@email.com',       '+91-9005556666', 'Bangalore', 'active'),
('Sneha',    'Patel',      'sneha.patel@email.com',      '+91-9007778888', 'Ahmedabad', 'active'),
('Vikram',   'Singh',      'vikram.singh@email.com',     '+91-9009990000', 'Jaipur',    'active'),
('Anjali',   'Nair',       'anjali.nair@email.com',      '+91-9112223333', 'Kochi',     'active'),
('Rohit',    'Gupta',      'rohit.gupta@email.com',      '+91-9224445555', 'Pune',      'active'),
('Divya',    'Joshi',      'divya.joshi@email.com',      '+91-9336667777', 'Hyderabad', 'active'),
('Kiran',    'Reddy',      'kiran.reddy@email.com',      '+91-9448889999', 'Chennai',   'active'),
('Meena',    'Pillai',     'meena.pillai@email.com',     '+91-9550001111', 'Kolkata',   'active');

-- ============================================================
-- SEED: orders
-- ============================================================
INSERT INTO orders (customer_id, product_id, quantity, total_price, order_status, order_date) VALUES
(1,  1,  1, 129999.00, 'delivered',   NOW() - INTERVAL '30 days'),
(2,  2,  1,  89999.00, 'delivered',   NOW() - INTERVAL '28 days'),
(3,  5,  2,  16998.00, 'shipped',     NOW() - INTERVAL '15 days'),
(4,  4,  1,   9999.00, 'processing',  NOW() - INTERVAL '10 days'),
(5,  6,  3,  14997.00, 'delivered',   NOW() - INTERVAL '25 days'),
(6,  9,  2,   6998.00, 'delivered',   NOW() - INTERVAL '20 days'),
(7,  12, 1,  69999.00, 'shipped',     NOW() - INTERVAL '5 days'),
(8,  3,  1, 179999.00, 'pending',     NOW() - INTERVAL '2 days'),
(9,  13, 1,   6999.00, 'delivered',   NOW() - INTERVAL '18 days'),
(10, 14, 2,   5998.00, 'processing',  NOW() - INTERVAL '7 days'),
(1,  11, 1,  49999.00, 'delivered',   NOW() - INTERVAL '45 days'),
(3,  7,  4,   9996.00, 'delivered',   NOW() - INTERVAL '40 days'),
(5,  10, 1,  15999.00, 'shipped',     NOW() - INTERVAL '3 days'),
(2,  15, 5,   2995.00, 'pending',     NOW() - INTERVAL '1 day'),
(8,  8,  1,  12999.00, 'cancelled',   NOW() - INTERVAL '12 days');

-- Indexes
CREATE INDEX idx_orders_customer    ON orders(customer_id);
CREATE INDEX idx_orders_product     ON orders(product_id);
CREATE INDEX idx_orders_status      ON orders(order_status);
CREATE INDEX idx_products_category  ON products(category);
CREATE INDEX idx_customers_email    ON customers(email);

-- Verify
SELECT 'products'  AS tbl, COUNT(*) AS rows FROM products
UNION ALL
SELECT 'customers' AS tbl, COUNT(*) AS rows FROM customers
UNION ALL
SELECT 'orders'    AS tbl, COUNT(*) AS rows FROM orders;
