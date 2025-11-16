-- Migración para corregir campos de nombre en la tabla usersbank
-- Ejecutar este script para actualizar la base de datos existente

-- Verificar si las columnas first_name y last_name existen
-- Si no existen, crearlas
ALTER TABLE usersbank 
ADD COLUMN IF NOT EXISTS first_name VARCHAR(50),
ADD COLUMN IF NOT EXISTS last_name VARCHAR(50);

-- Si existe la columna fist_name (con error tipográfico), migrar datos
UPDATE usersbank 
SET first_name = fist_name 
WHERE fist_name IS NOT NULL AND first_name IS NULL;

-- Opcional: Eliminar la columna con error tipográfico después de migrar
-- ALTER TABLE usersbank DROP COLUMN IF EXISTS fist_name;

-- Verificar la estructura actualizada
-- DESCRIBE usersbank;