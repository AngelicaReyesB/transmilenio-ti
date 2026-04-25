CREATE DATABASE IF NOT EXISTS transmilenio_db;
USE transmilenio_db;

CREATE TABLE rutas (
    id INT AUTO_INCREMENT PRIMARY KEY,
    codigo VARCHAR(10) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    origen VARCHAR(100),
    destino VARCHAR(100),
    activa BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE estaciones (
    id INT AUTO_INCREMENT PRIMARY KEY,
    nombre VARCHAR(100) NOT NULL,
    localidad VARCHAR(50),
    capacidad INT,
    activa BOOLEAN DEFAULT TRUE
);

INSERT INTO rutas (codigo, nombre, origen, destino) VALUES
('B18', 'Ruta B18', 'Portal Norte', 'Portal Sur'),
('K11', 'Ruta K11', 'Portal Eldorado', 'Calle 26'),
('J23', 'Ruta J23', 'Portal 80', 'Portal Americas');

INSERT INTO estaciones (nombre, localidad, capacidad) VALUES
('Portal Norte', 'Usaquén', 5000),
('Calle 26', 'Teusaquillo', 3000),
('Portal Sur', 'Bosa', 4500);
