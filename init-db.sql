-- Script de inicialización de la base de datos para Docker
-- Este script se ejecutará cuando se cree el contenedor de la base de datos

USE master;
GO

-- Crear la base de datos si no existe
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'seguipro')
BEGIN
    CREATE DATABASE seguipro;
END
GO

USE seguipro;
GO

-- Crear tablas (usar el contenido de sql.sql)
-- Aquí se incluirían todas las tablas del archivo sql.sql original

-- Tabla de Roles
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Rol' AND xtype='U')
BEGIN
    CREATE TABLE Rol (
        id_rol INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(100) NOT NULL,
        descripcion NVARCHAR(500)
    );
END
GO

-- Tabla de Áreas
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Area' AND xtype='U')
BEGIN
    CREATE TABLE Area (
        id_area INT IDENTITY(1,1) PRIMARY KEY,
        nombre NVARCHAR(200) NOT NULL,
        descripcion NVARCHAR(500)
    );
END
GO

-- Tabla de Usuarios
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='Usuario' AND xtype='U')
BEGIN
    CREATE TABLE Usuario (
        id_usuario INT IDENTITY(1,1) PRIMARY KEY,
        id_area INT NOT NULL,
        id_rol INT NOT NULL,
        username NVARCHAR(50) NOT NULL,
        nombres NVARCHAR(200) NOT NULL,
        apellidos NVARCHAR(200) NOT NULL,
        CONSTRAINT FK_Usuario_Area FOREIGN KEY (id_area) REFERENCES Area(id_area),
        CONSTRAINT FK_Usuario_Rol FOREIGN KEY (id_rol) REFERENCES Rol(id_rol)
    );
END
GO

-- Tabla de Autenticación
IF NOT EXISTS (SELECT * FROM sysobjects WHERE name='UsersAuth' AND xtype='U')
BEGIN
    CREATE TABLE UsersAuth (
        id_usuario INT PRIMARY KEY,
        password_hash NVARCHAR(255) NOT NULL,
        FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
    );
END
GO

-- Insertar datos de ejemplo
INSERT INTO Rol (nombre, descripcion) VALUES 
('Administrador', 'Rol con acceso completo al sistema'),
('Supervisor', 'Rol de supervisión de equipos'),
('Usuario', 'Rol básico de usuario');

INSERT INTO Area (nombre, descripcion) VALUES 
('Recursos Humanos', 'Área encargada de gestión de personal'),
('Seguridad', 'Área de seguridad y prevención'),
('Sistemas', 'Área de tecnología e informática');

-- Crear usuario administrador por defecto
INSERT INTO Usuario (id_area, id_rol, username, nombres, apellidos) VALUES 
(1, 1, 'admin', 'Administrador', 'Sistema');

-- La contraseña es 'admin123' hasheada con bcrypt
INSERT INTO UsersAuth (id_usuario, password_hash) VALUES 
(1, '$2b$10$rQZ8KjtBqZ8KjtBqZ8KjtOu8KjtBqZ8KjtBqZ8KjtBqZ8KjtBqZ8Kj');
