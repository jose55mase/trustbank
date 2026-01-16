-- Script para hacer la descripción opcional en la tabla expenses
-- Ejecutar solo si la tabla ya existe con datos

ALTER TABLE expenses MODIFY COLUMN description VARCHAR(255) NULL;