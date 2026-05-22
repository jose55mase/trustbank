-- Datos de prueba para H2

-- Roles
INSERT INTO rolsbank (id, name) VALUES(1, 'ROLE_USER');
INSERT INTO rolsbank (id, name) VALUES(2, 'ROLE_ADMIN');

-- Usuario de prueba (password: 12345)
INSERT INTO usersbank (id, aboutme, city, country, document, documents_aprov, email, fist_name, last_name, moneyclean, password, postal, status, username, account_status, phone, created_at, updated_at) VALUES(1, '', 'Santiago', 'Chile', '15263654', '{"foto":false,"fromt":false,"back":false}', 'user@test.com', 'Usuario', 'Prueba', 5000, '$2a$10$RmdEsvEfhI7Rcm9f/uZXPebZVCcPC7ZXZwV51efAvMAp1rIaRAfPK', '', true, 'testuser', 'ACTIVE', '+56912345678', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Admin de prueba (password: 12345)
INSERT INTO usersbank (id, aboutme, city, country, document, documents_aprov, email, fist_name, last_name, moneyclean, password, postal, status, username, account_status, phone, created_at, updated_at) VALUES(2, '', 'Santiago', 'Chile', '15263655', '{"foto":false,"fromt":false,"back":false}', 'admin@test.com', 'Admin', 'TrustBank', 10000, '$2a$10$RmdEsvEfhI7Rcm9f/uZXPebZVCcPC7ZXZwV51efAvMAp1rIaRAfPK', '', true, 'admin', 'ACTIVE', '+56987654321', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Asignar roles
INSERT INTO usersbank_rols (user_entity_id, rols_id) VALUES(1, 1);
INSERT INTO usersbank_rols (user_entity_id, rols_id) VALUES(2, 2);
