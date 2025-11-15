-- Migración para agregar columna role a la tabla users
-- Ejecutar en el backend Spring Boot (spring-boot-backend-apirest)

-- 1. Agregar columna role
ALTER TABLE users ADD COLUMN role VARCHAR(20) DEFAULT 'USER';

-- 2. Crear índice para consultas por rol
CREATE INDEX idx_users_role ON users(role);

-- 3. Insertar usuario administrador por defecto
INSERT INTO users (
    name, 
    email, 
    password, 
    role, 
    moneyclean, 
    balance, 
    phone, 
    address, 
    documentType, 
    documentNumber, 
    accountStatus, 
    createdAt, 
    updatedAt
) VALUES (
    'Administrador TrustBank',
    'admin@trustbank.com',
    '$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi', -- password: admin123
    'SUPER_ADMIN',
    1000000.00,
    1000000.00,
    '+1234567890',
    'Oficina Central TrustBank',
    'CC',
    '12345678',
    'ACTIVE',
    NOW(),
    NOW()
) ON DUPLICATE KEY UPDATE role = 'SUPER_ADMIN';

-- 4. Actualizar usuarios existentes
UPDATE users SET role = 'USER' WHERE role IS NULL OR role = '';

-- 5. Hacer columna NOT NULL
ALTER TABLE users MODIFY COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';