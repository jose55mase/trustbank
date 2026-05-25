-- Migración: Crear tablas para el sistema de asignación de supervisores
-- Feature: Supervisor Lead Assignments
-- Requirements: 1.1, 1.3, 2.7, 7.1
-- Ejecutar este script para crear las tablas de tipos de asignación y asignaciones de supervisor

-- Tabla de tipos de asignación
CREATE TABLE IF NOT EXISTS assignment_types (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL UNIQUE,
    description VARCHAR(255),
    active BOOLEAN NOT NULL DEFAULT TRUE,
    filter_value VARCHAR(100),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Tabla de asignaciones supervisor-tipo
CREATE TABLE IF NOT EXISTS supervisor_assignments (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    user_id BIGINT NOT NULL,
    assignment_type_id BIGINT NOT NULL,
    assigned_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES usersbank(id) ON DELETE CASCADE,
    FOREIGN KEY (assignment_type_id) REFERENCES assignment_types(id) ON DELETE RESTRICT,
    UNIQUE (user_id)
);

-- Nuevo rol SUPERVISOR
INSERT INTO rolsbank (id, name) VALUES(4, 'ROLE_SUPERVISOR');

-- Nuevo módulo en el catálogo
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES
(6, 'SUPERVISOR_ASSIGNMENTS', 'Tipos de Asignación', 'Gestionar tipos de asignación de supervisores', 'assignment', 6);

-- Asignar módulo SUPERVISOR_ASSIGNMENTS a ROLE_ADMIN (id=2) y ROLE_SUPER_ADMIN (id=3)
INSERT INTO role_modules (role_id, module_id) VALUES(2, 6);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 6);

-- Asignar módulo LEADS a ROLE_SUPERVISOR (id=4)
INSERT INTO role_modules (role_id, module_id) VALUES(4, 1);
