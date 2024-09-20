

/* Creamos algunos usuarios con sus roles */
INSERT INTO guardianstrustbank.usersbank (aboutme, city, country, document,documents_aprov ,email, fist_name, last_name, moneyclean, password, postal, status, username) VALUES ("", "", "", "15263654","{\"foto\":false,\"fromt\":false,\"back\":false}", "develop@dev.com", "Develop", "Dev Deverp", 54, "$2a$10$RmdEsvEfhI7Rcm9f/uZXPebZVCcPC7ZXZwV51efAvMAp1rIaRAfPK", "", 1, "Develop");
INSERT INTO guardianstrustbank.usersbank (aboutme, city, country, document, email, fist_name, last_name, moneyclean, password, postal, status, username) VALUES("", "", "", "15263654", "developadmin@dev.com", "Administrator", "admin admin", 1003, "$2a$10$C3Uln5uqnzx/GswADURJGOIdBqYrly9731fnwKDaUdBkt/M3qvtLq", "", 1, "Administrator");

INSERT INTO guardianstrustbank.rolsbank (name) VALUES('ROLE_USER');
INSERT INTO guardianstrustbank.rolsbank (name) VALUES('ROLE_ADMIN');

INSERT INTO guardianstrustbank.usersbank_rols (user_entity_id, rols_id) VALUES(1, 1);
INSERT INTO guardianstrustbank.usersbank_rols (user_entity_id, rols_id) VALUES(2, 2);