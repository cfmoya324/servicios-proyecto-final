CREATE DATABASE IF NOT EXISTS api_vm3;
USE api_vm3;

CREATE TABLE IF NOT EXISTS info_servidor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    ip VARCHAR(20),
    rol VARCHAR(50),
    estado VARCHAR(20),
    mensaje VARCHAR(100),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO info_servidor (ip, rol, estado, mensaje)
VALUES ('192.168.56.4', 'Servidor de aplicación Apache', 'En línea', 'Servidor 3 operativo');

CREATE USER 'vm3_user'@'localhost' IDENTIFIED BY 'vm3_pass';
GRANT ALL PRIVILEGES ON api_vm3.* TO 'vm3_user'@'localhost';
FLUSH PRIVILEGES;
