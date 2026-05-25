-- Datos de prueba para H2

-- Roles
INSERT INTO rolsbank (id, name) VALUES(1, 'ROLE_USER');
INSERT INTO rolsbank (id, name) VALUES(2, 'ROLE_ADMIN');
INSERT INTO rolsbank (id, name) VALUES(3, 'ROLE_SUPER_ADMIN');
INSERT INTO rolsbank (id, name) VALUES(4, 'ROLE_SUPERVISOR');

-- Usuario de prueba (password: 12345)
INSERT INTO usersbank (id, aboutme, city, country, document, documents_aprov, email, fist_name, last_name, moneyclean, password, postal, status, username, account_status, phone, created_at, updated_at) VALUES(1, '', 'Santiago', 'Chile', '15263654', '{"foto":false,"fromt":false,"back":false}', 'user@test.com', 'Usuario', 'Prueba', 5000, '$2a$10$RmdEsvEfhI7Rcm9f/uZXPebZVCcPC7ZXZwV51efAvMAp1rIaRAfPK', '', true, 'testuser', 'ACTIVE', '+56912345678', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Admin de prueba (password: 12345)
INSERT INTO usersbank (id, aboutme, city, country, document, documents_aprov, email, fist_name, last_name, moneyclean, password, postal, status, username, account_status, phone, created_at, updated_at) VALUES(2, '', 'Santiago', 'Chile', '15263655', '{"foto":false,"fromt":false,"back":false}', 'admin@test.com', 'Admin', 'TrustBank', 10000, '$2a$10$RmdEsvEfhI7Rcm9f/uZXPebZVCcPC7ZXZwV51efAvMAp1rIaRAfPK', '', true, 'admin', 'ACTIVE', '+56987654321', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Super Admin (password: superadmin123)
INSERT INTO usersbank (id, aboutme, city, country, document, documents_aprov, email, fist_name, last_name, moneyclean, password, postal, status, username, account_status, phone, created_at, updated_at) VALUES(3, '', 'Santiago', 'Chile', '99999999', '{"foto":false,"fromt":false,"back":false}', 'superadmin@guardianstrustbank.com', 'Super', 'Admin', 0, '$2b$10$qLfd5/w10qzkrCEW9JgWTO5WF4xS0MaaTJe/1/14QQYtrGtKikMT6', '', true, 'superadmin', 'ACTIVE', '+56900000000', CURRENT_TIMESTAMP, CURRENT_TIMESTAMP);

-- Asignar roles
INSERT INTO usersbank_rols (user_entity_id, rols_id) VALUES(1, 1);
INSERT INTO usersbank_rols (user_entity_id, rols_id) VALUES(2, 2);
INSERT INTO usersbank_rols (user_entity_id, rols_id) VALUES(3, 3);

-- Catálogo de módulos
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(1, 'LEADS', 'Leads', 'Gestión de leads y prospectos', 'leaderboard', 1);
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(2, 'DOCUMENTS', 'Documentos', 'Gestión de documentos de usuarios', 'description', 2);
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(3, 'DOCUMENT_APPROVAL', 'Aprobación de Documentos', 'Aprobar o rechazar documentos', 'verified', 3);
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(4, 'USER_MANAGEMENT', 'Gestión de Usuarios', 'Administrar usuarios del sistema', 'group', 4);
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(5, 'ROLE_MANAGEMENT', 'Gestión de Roles', 'Administrar roles y permisos', 'admin_panel_settings', 5);
INSERT INTO modules (id, code, name, description, icon, display_order) VALUES(6, 'SUPERVISOR_ASSIGNMENTS', 'Tipos de Asignación', 'Gestionar tipos de asignación de supervisores', 'assignment', 6);

-- Asignar todos los módulos a ROLE_ADMIN (id=2)
INSERT INTO role_modules (role_id, module_id) VALUES(2, 1);
INSERT INTO role_modules (role_id, module_id) VALUES(2, 2);
INSERT INTO role_modules (role_id, module_id) VALUES(2, 3);
INSERT INTO role_modules (role_id, module_id) VALUES(2, 4);
INSERT INTO role_modules (role_id, module_id) VALUES(2, 5);
INSERT INTO role_modules (role_id, module_id) VALUES(2, 6);

-- Asignar todos los módulos a ROLE_SUPER_ADMIN (id=3)
INSERT INTO role_modules (role_id, module_id) VALUES(3, 1);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 2);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 3);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 4);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 5);
INSERT INTO role_modules (role_id, module_id) VALUES(3, 6);

-- Asignar módulos básicos a ROLE_USER (id=1) - solo Leads y Documentos
INSERT INTO role_modules (role_id, module_id) VALUES(1, 1);
INSERT INTO role_modules (role_id, module_id) VALUES(1, 2);

-- Asignar módulo LEADS a ROLE_SUPERVISOR (id=4)
INSERT INTO role_modules (role_id, module_id) VALUES(4, 1);
