-- Insertar datos de ejemplo para las nuevas tablas

-- Notificaciones
INSERT INTO notifications (user_id, title, message, type, is_read, created_at) VALUES
(1, 'Crédito Aprobado ✅', 'Tu solicitud de Crédito Personal por $5,000 ha sido aprobada. Revisa los términos y condiciones.', 'credit', false, NOW() - INTERVAL 2 HOUR),
(1, 'Solicitud en Revisión ⏳', 'Tu solicitud de Crédito Vehicular está siendo evaluada. Te contactaremos pronto.', 'credit', false, NOW() - INTERVAL 1 DAY),
(1, 'Bienvenido a TrustBank 🎉', 'Gracias por unirte a nuestra familia financiera. Explora todos nuestros servicios.', 'general', true, NOW() - INTERVAL 3 DAY);

-- Créditos
INSERT INTO credits (user_id, credit_type, amount, term_months, interest_rate, monthly_payment, status, created_at) VALUES
(1, 'Crédito Personal', 5000.00, 24, 12.5, 235.84, 'APPROVED', NOW() - INTERVAL 1 DAY),
(1, 'Crédito Vehicular', 25000.00, 60, 8.9, 518.26, 'PENDING', NOW() - INTERVAL 2 HOUR);

-- Actualizar usuario con documentos aprobados
UPDATE usersbank SET documentsAprov = '{"foto":true,"fromt":true,"back":true}', status = true WHERE id = 1;