-- Script para limpiar datos de prueba de la base de datos
-- Ejecutar este script para eliminar datos de ejemplo/prueba

-- Limpiar notificaciones de prueba
DELETE FROM notifications 
WHERE user_name = 'Juan Pérez' 
   OR message LIKE '%ejemplo%' 
   OR message LIKE '%prueba%'
   OR additional_info LIKE '%Tarjeta de crédito **** 1234%';

-- Limpiar solicitudes administrativas de prueba
DELETE FROM admin_requests 
WHERE details LIKE '%María García%' 
   OR details LIKE '%tarjeta de crédito%'
   OR details LIKE '%Crédito personal - 24 meses%'
   OR (user_id = 1 AND status = 'APPROVED' AND amount = 10000.00);

-- Limpiar documentos de prueba
DELETE FROM documents 
WHERE file_name IN ('cedula.pdf', 'recibo_luz.pdf')
   OR file_path LIKE '/uploads/%'
   OR admin_notes = 'Documento válido';

-- Opcional: Resetear saldo de usuarios de prueba a 0
-- UPDATE usersbank SET moneyclean = 0 WHERE id IN (1, 2, 3);

-- Verificar limpieza
SELECT 'Notificaciones restantes:' as tabla, COUNT(*) as cantidad FROM notifications
UNION ALL
SELECT 'Solicitudes restantes:', COUNT(*) FROM admin_requests  
UNION ALL
SELECT 'Documentos restantes:', COUNT(*) FROM documents;