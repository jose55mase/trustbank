-- Migración: Crear tablas para permisos granulares por módulo y visibilidad de campañas
-- Feature: Granular Module Permissions
-- Requirements: 1.1, 1.2, 4.1
-- Ejecutar este script para crear las tablas de permisos de acción y visibilidad de campañas por rol

-- Tabla de permisos de acción por rol-módulo
-- Almacena permisos individuales (booleanos) para cada acción dentro de un módulo asignado a un rol
CREATE TABLE IF NOT EXISTS role_module_permissions (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    module_id BIGINT NOT NULL,
    action_code VARCHAR(30) NOT NULL,
    enabled BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT fk_rmp_role FOREIGN KEY (role_id) REFERENCES rolsbank(id) ON DELETE CASCADE,
    CONSTRAINT fk_rmp_module FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE,
    CONSTRAINT uq_rmp_role_module_action UNIQUE (role_id, module_id, action_code)
);

-- Índice compuesto para consultas por rol y módulo
CREATE INDEX idx_rmp_role_module ON role_module_permissions(role_id, module_id);

-- Tabla de visibilidad de campañas por rol
-- Almacena qué campañas puede ver cada rol (si no hay registros, el rol ve todas las campañas)
CREATE TABLE IF NOT EXISTS role_campaign_visibility (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    role_id BIGINT NOT NULL,
    campaign_id BIGINT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_rcv_role FOREIGN KEY (role_id) REFERENCES rolsbank(id) ON DELETE CASCADE,
    CONSTRAINT fk_rcv_campaign FOREIGN KEY (campaign_id) REFERENCES assignment_types(id) ON DELETE CASCADE,
    CONSTRAINT uq_rcv_role_campaign UNIQUE (role_id, campaign_id)
);

-- Índice para consultas por rol
CREATE INDEX idx_rcv_role ON role_campaign_visibility(role_id);
