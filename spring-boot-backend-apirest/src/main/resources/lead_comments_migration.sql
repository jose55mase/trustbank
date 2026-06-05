-- Migración: Crear tabla lead_comments para comentarios con autoría
-- Feature: Protected Lead Comments (Comentarios protegidos por autor)
-- Requirements: 1.1, 1.2, 1.3, 1.4
-- Ejecutar este script para crear la tabla de comentarios con trazabilidad de autor.
-- NOTA: La columna 'comentarios' en la tabla 'leads' NO se modifica.

-- Crear tabla lead_comments
CREATE TABLE IF NOT EXISTS lead_comments (
    id BIGINT NOT NULL AUTO_INCREMENT,
    lead_id BIGINT NOT NULL,
    user_id BIGINT NOT NULL,
    text VARCHAR(2000) NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    edited_at TIMESTAMP NULL,
    PRIMARY KEY (id),
    CONSTRAINT fk_lead_comments_lead FOREIGN KEY (lead_id) REFERENCES leads(id) ON DELETE CASCADE,
    CONSTRAINT fk_lead_comments_user FOREIGN KEY (user_id) REFERENCES usersbank(id) ON DELETE RESTRICT,
    INDEX idx_lead_comments_lead_id (lead_id),
    INDEX idx_lead_comments_user_id (user_id)
);
