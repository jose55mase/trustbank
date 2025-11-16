-- Migración para agregar campos de usuario a la tabla notifications
-- Ejecutar este script para actualizar la base de datos existente

-- Agregar nuevos campos a la tabla notifications
ALTER TABLE notifications 
ADD COLUMN user_name VARCHAR(255),
ADD COLUMN user_email VARCHAR(255),
ADD COLUMN user_phone VARCHAR(50),
ADD COLUMN additional_info TEXT;

-- Actualizar registros existentes con datos de ejemplo (opcional)
-- UPDATE notifications SET 
--     user_name = 'Usuario',
--     user_email = 'usuario@trustbank.com',
--     user_phone = '+1 234 567 8900',
--     additional_info = 'Información migrada'
-- WHERE user_name IS NULL;

-- Verificar la estructura actualizada
-- DESCRIBE notifications;