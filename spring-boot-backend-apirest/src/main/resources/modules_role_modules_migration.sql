-- Migración: Crear tabla de módulos y tabla junction role_modules
-- Feature: Role-Based Module Access
-- Requirements: 6.1, 6.2
-- Ejecutar este script para crear las tablas de módulos y la relación roles-módulos

-- Tabla de módulos (catálogo)
CREATE TABLE IF NOT EXISTS modules (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    description VARCHAR(255),
    icon VARCHAR(50),
    display_order INT NOT NULL DEFAULT 0
);

-- Tabla junction role-modules (relación many-to-many entre roles y módulos)
CREATE TABLE IF NOT EXISTS role_modules (
    role_id BIGINT NOT NULL,
    module_id BIGINT NOT NULL,
    PRIMARY KEY (role_id, module_id),
    FOREIGN KEY (role_id) REFERENCES rolsbank(id) ON DELETE CASCADE,
    FOREIGN KEY (module_id) REFERENCES modules(id) ON DELETE CASCADE
);

-- Datos iniciales del catálogo de módulos
INSERT INTO modules (code, name, description, icon, display_order) VALUES
('LEADS', 'Leads', 'Gestión de leads y prospectos', 'leaderboard', 1),
('DOCUMENTS', 'Documentos', 'Gestión de documentos de usuarios', 'description', 2),
('DOCUMENT_APPROVAL', 'Aprobación de Documentos', 'Aprobar o rechazar documentos', 'verified', 3),
('USER_MANAGEMENT', 'Gestión de Usuarios', 'Administrar usuarios del sistema', 'group', 4),
('ROLE_MANAGEMENT', 'Gestión de Roles', 'Administrar roles y permisos', 'admin_panel_settings', 5);

-- Asignar TODOS los módulos a los roles de administrador existentes
-- Ajusta los IDs según tu base de datos (consulta: SELECT id, name FROM rolsbank)
INSERT INTO role_modules (role_id, module_id)
SELECT r.id, m.id FROM rolsbank r, modules m WHERE r.name = 'ROLE_ADMIN';

INSERT INTO role_modules (role_id, module_id)
SELECT r.id, m.id FROM rolsbank r, modules m WHERE r.name = 'ROLE_SUPER_ADMIN';

-- Asignar módulos básicos a ROLE_USER (solo Leads y Documentos)
INSERT INTO role_modules (role_id, module_id)
SELECT r.id, m.id FROM rolsbank r, modules m
WHERE r.name = 'ROLE_USER' AND m.code IN ('LEADS', 'DOCUMENTS');
