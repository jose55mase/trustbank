-- Tabla de usuarios
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    user_code VARCHAR(50),
    phone VARCHAR(50) NOT NULL,
    email VARCHAR(255) NOT NULL,
    registration_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de préstamos con columnas de control de pago
CREATE TABLE IF NOT EXISTS loans (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    interest_rate DECIMAL(5,2) NOT NULL,
    installments INTEGER NOT NULL,
    paid_installments INTEGER DEFAULT 0,
    start_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status VARCHAR(20) DEFAULT 'ACTIVE',
    previous_status VARCHAR(20),
    status_change_date TIMESTAMP,
    pago_anterior BOOLEAN DEFAULT FALSE,
    pago_actual BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (user_id) REFERENCES users(id)
);

-- Tabla de transacciones
CREATE TABLE IF NOT EXISTS transactions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    type VARCHAR(20) NOT NULL,
    loan_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    payment_method VARCHAR(20) NOT NULL,
    notes VARCHAR(500),
    interest_amount DECIMAL(15,2),
    principal_amount DECIMAL(15,2),
    FOREIGN KEY (loan_id) REFERENCES loans(id)
);

-- Tabla para documentos de usuarios
CREATE TABLE IF NOT EXISTS documents (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    file_name VARCHAR(255) NOT NULL,
    file_path VARCHAR(500) NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    uploaded_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    admin_notes TEXT NULL
);

-- Índices para la tabla documents
CREATE INDEX IF NOT EXISTS idx_documents_user_id ON documents (user_id);
CREATE INDEX IF NOT EXISTS idx_documents_status ON documents (status);
CREATE INDEX IF NOT EXISTS idx_documents_document_type ON documents (document_type);

-- Tabla para solicitudes administrativas
CREATE TABLE IF NOT EXISTS admin_requests (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    request_type VARCHAR(50) NOT NULL,
    user_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    details TEXT NOT NULL,
    status VARCHAR(20) DEFAULT 'PENDING',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    processed_at TIMESTAMP NULL,
    admin_notes TEXT NULL
);

-- Índices para la tabla admin_requests
CREATE INDEX IF NOT EXISTS idx_admin_requests_user_id ON admin_requests (user_id);
CREATE INDEX IF NOT EXISTS idx_admin_requests_status ON admin_requests (status);
CREATE INDEX IF NOT EXISTS idx_admin_requests_request_type ON admin_requests (request_type);
CREATE INDEX IF NOT EXISTS idx_admin_requests_created_at ON admin_requests (created_at);

-- Tabla para notificaciones con datos de usuario
CREATE TABLE IF NOT EXISTS notifications (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    title VARCHAR(255) NOT NULL,
    message TEXT NOT NULL,
    type VARCHAR(50) NOT NULL,
    is_read BOOLEAN DEFAULT FALSE,
    user_name VARCHAR(255),
    user_email VARCHAR(255),
    user_phone VARCHAR(50),
    additional_info TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para la tabla notifications
CREATE INDEX IF NOT EXISTS idx_notifications_user_id ON notifications (user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications (type);
CREATE INDEX IF NOT EXISTS idx_notifications_is_read ON notifications (is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications (created_at);

-- Tabla de categorías de gastos
CREATE TABLE IF NOT EXISTS expense_categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    icon_name VARCHAR(50) NOT NULL,
    color_value VARCHAR(10) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Índices para la tabla expense_categories
CREATE INDEX IF NOT EXISTS idx_expense_categories_name ON expense_categories (name);
CREATE INDEX IF NOT EXISTS idx_expense_categories_created_at ON expense_categories (created_at);

-- Tabla de gastos
CREATE TABLE IF NOT EXISTS expenses (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    category_id BIGINT NOT NULL,
    amount DECIMAL(15,2) NOT NULL,
    description VARCHAR(500) NOT NULL,
    expense_date TIMESTAMP NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES expense_categories(id)
);

-- Índices para la tabla expenses
CREATE INDEX IF NOT EXISTS idx_expenses_category_id ON expenses (category_id);
CREATE INDEX IF NOT EXISTS idx_expenses_expense_date ON expenses (expense_date);
CREATE INDEX IF NOT EXISTS idx_expenses_created_at ON expenses (created_at);

-- Datos de prueba para usuarios
INSERT INTO users (name, user_code, phone, email, registration_date) VALUES
('Juan Pérez', 'USR001', '+1234567890', 'juan.perez@email.com', '2024-01-15 10:00:00'),
('María García', 'USR002', '+1234567891', 'maria.garcia@email.com', '2024-01-20 14:30:00'),
('Carlos Rodríguez', 'USR003', '+1234567892', 'carlos.rodriguez@email.com', '2024-02-01 09:15:00');

-- Datos de prueba para préstamos
INSERT INTO loans (user_id, amount, interest_rate, installments, paid_installments, start_date, status) VALUES
(1, 5000000.00, 15.0, 12, 5, '2024-01-15 10:30:00', 'ACTIVE'),
(2, 10000000.00, 12.0, 24, 10, '2024-01-20 15:00:00', 'ACTIVE'),
(1, 7500000.00, 14.0, 18, 8, '2024-02-01 11:00:00', 'ACTIVE');

-- Datos de prueba para transacciones
INSERT INTO transactions (type, loan_id, amount, date, payment_method, notes, interest_amount, principal_amount) VALUES
('PAYMENT', 1, 520833.33, '2024-02-15 10:00:00', 'TRANSFER', 'Pago cuota 1', 62500.00, 458333.33),
('PAYMENT', 1, 520833.33, '2024-03-15 10:00:00', 'CASH', 'Pago cuota 2', 60729.17, 460104.16),
('PAYMENT', 2, 520833.33, '2024-02-20 14:00:00', 'CHECK', 'Pago cuota 1', 100000.00, 420833.33);

-- Datos de prueba para categorías de gastos
INSERT INTO expense_categories (name, icon_name, color_value, created_at) VALUES
('Comida', 'restaurant', 'ff9800', '2024-01-01 00:00:00'),
('Ropa', 'shopping_bag', '9c27b0', '2024-01-01 00:00:00'),
('Transporte', 'directions_car', '2196f3', '2024-01-01 00:00:00'),
('Entretenimiento', 'movie', 'e91e63', '2024-01-01 00:00:00'),
('Salud', 'medical_services', 'f44336', '2024-01-01 00:00:00'),
('Hogar', 'home', '4caf50', '2024-01-01 00:00:00'),
('Educación', 'school', '673ab7', '2024-01-01 00:00:00'),
('Servicios', 'build', '607d8b', '2024-01-01 00:00:00');

