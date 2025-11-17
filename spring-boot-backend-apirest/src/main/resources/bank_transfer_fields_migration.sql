-- Migración para agregar campos específicos de transferencias bancarias
-- Fecha: 2024

ALTER TABLE admin_requests 
ADD COLUMN bank_name VARCHAR(100),
ADD COLUMN account_number VARCHAR(50),
ADD COLUMN transfer_type VARCHAR(50),
ADD COLUMN description TEXT;

-- Comentarios para documentación
COMMENT ON COLUMN admin_requests.bank_name IS 'Nombre del banco destino';
COMMENT ON COLUMN admin_requests.account_number IS 'Número de cuenta destino';
COMMENT ON COLUMN admin_requests.transfer_type IS 'Tipo de transferencia';
COMMENT ON COLUMN admin_requests.description IS 'Descripción de la transferencia';