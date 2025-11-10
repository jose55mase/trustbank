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
    admin_notes TEXT NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_document_type (document_type)
);

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
    admin_notes TEXT NULL,
    INDEX idx_user_id (user_id),
    INDEX idx_status (status),
    INDEX idx_request_type (request_type),
    INDEX idx_created_at (created_at)
);

-- Insertar datos de ejemplo
INSERT INTO admin_requests (request_type, user_id, amount, details, status, created_at) VALUES
('SEND_MONEY', 1, 150.00, 'Envío a María García', 'PENDING', NOW() - INTERVAL 2 HOUR),
('RECHARGE', 1, 500.00, 'Recarga con tarjeta de crédito', 'PENDING', NOW() - INTERVAL 1 HOUR),
('CREDIT', 1, 10000.00, 'Crédito personal - 24 meses', 'APPROVED', NOW() - INTERVAL 1 DAY);

INSERT INTO documents (user_id, document_type, file_name, file_path, status, uploaded_at, processed_at, admin_notes) VALUES
(1, 'ID', 'cedula.pdf', '/uploads/cedula.pdf', 'APPROVED', NOW() - INTERVAL 2 DAY, NOW() - INTERVAL 1 DAY, 'Documento válido'),
(1, 'PROOF_OF_ADDRESS', 'recibo_luz.pdf', '/uploads/recibo_luz.pdf', 'PENDING', NOW() - INTERVAL 5 HOUR, NULL, NULL);