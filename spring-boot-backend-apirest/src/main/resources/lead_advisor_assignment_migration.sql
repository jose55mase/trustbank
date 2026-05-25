-- Migración: Agregar columna advisor_id a la tabla leads
-- Feature: Asignación Directa de Leads a Asesores
-- Requirements: 1.1, 1.2, 1.3, 1.5
-- Ejecutar este script para agregar la relación directa lead → asesor

-- Agregar columna advisor_id (nullable) a la tabla leads
ALTER TABLE leads ADD COLUMN advisor_id BIGINT NULL;

-- Crear FK hacia usersbank con ON DELETE SET NULL
ALTER TABLE leads ADD CONSTRAINT fk_leads_advisor
    FOREIGN KEY (advisor_id) REFERENCES usersbank(id)
    ON DELETE SET NULL;

-- Índice para optimizar consultas por advisor_id
CREATE INDEX idx_leads_advisor_id ON leads(advisor_id);
