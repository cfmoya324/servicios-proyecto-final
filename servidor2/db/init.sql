CREATE DATABASE IF NOT EXISTS api_vm;
USE api_vm;

CREATE TABLE IF NOT EXISTS info_servidor (
    id INT AUTO_INCREMENT PRIMARY KEY,
    servidor VARCHAR(50),
    ip VARCHAR(20),
    rol VARCHAR(50),
    estado VARCHAR(20),
    mensaje VARCHAR(100),
    fecha_actualizacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO info_servidor (servidor, ip, rol, estado, mensaje)
VALUES ('Servidor 2 (VM2)', '192.168.56.3', 'Servidor de aplicación Apache', 'En línea', 'Servidor 2 operativo');

INSERT INTO info_servidor (servidor, ip, rol, estado, mensaje)
VALUES ('Servidor 3 (VM3)', '192.168.56.4', 'Servidor de aplicación Apache', 'En línea', 'Servidor 3 operativo');

CREATE USER 'vm_user'@'localhost' IDENTIFIED BY 'vm_pass';
GRANT ALL PRIVILEGES ON api_vm.* TO 'vm_user'@'localhost';
FLUSH PRIVILEGES;
