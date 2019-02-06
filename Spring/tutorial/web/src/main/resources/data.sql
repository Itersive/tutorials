INSERT INTO roles (name) VALUES ('ROLE_USER');
INSERT INTO roles (name) VALUES ('ROLE_ADMIN');
INSERT INTO roles (name) VALUES ('ROLE_DBA');

INSERT INTO users (username, email, password) VALUES ('Wojtek', 'wpater@itersive.com', '$2a$10$BKNga0Jm./q71wvHABuDGO1oxRtiIOgh2PgKYmVN6dGqIA1jUWE8S');

INSERT INTO users_roles (user_id, roles_id) VALUES (1, 1);
INSERT INTO users_roles (user_id, roles_id) VALUES (1, 2);
INSERT INTO users_roles (user_id, roles_id) VALUES (1, 3);