
-- =============================================
-- CREACIÓN DE TABLAS PARA EL SISTEMA DE SEGUIMIENTO DE CASOS
-- =============================================
CREATE DATABASE seguipro
go
USE seguipro
go

-- Eliminamos las tablas si ya existen (para pruebas)
IF OBJECT_ID('Adjunto', 'U') IS NOT NULL DROP TABLE Adjunto;
IF OBJECT_ID('Seguimiento', 'U') IS NOT NULL DROP TABLE Seguimiento;
IF OBJECT_ID('CasoArea', 'U') IS NOT NULL DROP TABLE CasoArea;
IF OBJECT_ID('Caso', 'U') IS NOT NULL DROP TABLE Caso;
IF OBJECT_ID('Usuario', 'U') IS NOT NULL DROP TABLE Usuario;
IF OBJECT_ID('Area', 'U') IS NOT NULL DROP TABLE Area;

-- =============================================
-- TABLA DE ÁREAS
-- =============================================
CREATE TABLE Area (
    id_area INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,
    descripcion NVARCHAR(255) NULL
);

-- =============================================
-- TABLA DE ROLES
-- =============================================
CREATE TABLE Rol (
    id_rol INT IDENTITY(1,1) PRIMARY KEY,
    nombre NVARCHAR(100) NOT NULL,-- Ejemplo: Responsable, Administrador, Colaborador
    descripcion NVARCHAR(255) NULL
);

-- =============================================
-- TABLA DE USUARIOS
-- =============================================
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

IF OBJECT_ID('UsersAuth') IS NULL
      CREATE TABLE UsersAuth (
        id_usuario INT PRIMARY KEY,
        password_hash NVARCHAR(500) NOT NULL
      );
-- =============================================
-- TABLA DE CASOS
-- =============================================
CREATE TABLE Caso (
    id_caso INT IDENTITY(1,1) PRIMARY KEY,
    titulo NVARCHAR(200) NOT NULL,
    descripcion NVARCHAR(MAX) NULL,
    tipo NVARCHAR(50) NOT NULL, -- Ejemplo: Accidente, Médico, Proceso
    estado NVARCHAR(20) NOT NULL CHECK (estado IN ('Iniciado', 'En proceso', 'Finalizado')),
    fecha_creacion DATETIME NOT NULL DEFAULT GETDATE(),
    fecha_cierre DATETIME NULL
);

-- =============================================
-- TABLA INTERMEDIA CASO - ÁREA (N:M)
-- =============================================
CREATE TABLE CasoArea (
    id_caso_area INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    id_area INT NOT NULL,
    rol_area NVARCHAR(100) NULL, -- Ejemplo: Responsable, Colaboradora, Supervisora
    fecha_asignacion DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_CasoArea_Caso FOREIGN KEY (id_caso) REFERENCES Caso(id_caso),
    CONSTRAINT FK_CasoArea_Area FOREIGN KEY (id_area) REFERENCES Area(id_area),
    CONSTRAINT UQ_CasoArea UNIQUE (id_caso, id_area) -- Evita duplicados
);

-- =============================================
-- TABLA DE SEGUIMIENTOS
-- =============================================
CREATE TABLE Seguimiento (
    id_seguimiento INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NOT NULL,
    id_usuario INT NOT NULL,
    fecha_seguimiento DATETIME NOT NULL DEFAULT GETDATE(),
    retroalimentacion NVARCHAR(MAX) NOT NULL,
    estado NVARCHAR(20) NOT NULL CHECK (estado IN ('Iniciado', 'En proceso', 'Finalizado')),
    CONSTRAINT FK_Seguimiento_Caso FOREIGN KEY (id_caso) REFERENCES Caso(id_caso),
    CONSTRAINT FK_Seguimiento_Usuario FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);

-- =============================================
-- TABLA DE ADJUNTOS
-- =============================================
CREATE TABLE Adjunto (
    id_adjunto INT IDENTITY(1,1) PRIMARY KEY,
    id_caso INT NULL,
    id_seguimiento INT NULL,
    nombre_archivo NVARCHAR(255) NOT NULL,
    tipo_mime NVARCHAR(100) NOT NULL, -- Ejemplo: image/png, application/pdf
    ruta_archivo NVARCHAR(500) NULL,  -- Si se guardan en disco/nube
    archivo VARBINARY(MAX) NULL,      -- Si se guardan en la BD
    fecha_subida DATETIME NOT NULL DEFAULT GETDATE(),
    id_usuario INT NOT NULL,          -- Quién subió el archivo
    CONSTRAINT FK_Adjunto_Caso FOREIGN KEY (id_caso) REFERENCES Caso(id_caso),
    CONSTRAINT FK_Adjunto_Seguimiento FOREIGN KEY (id_seguimiento) REFERENCES Seguimiento(id_seguimiento),
    CONSTRAINT FK_Adjunto_Usuario FOREIGN KEY (id_usuario) REFERENCES Usuario(id_usuario)
);

-- =============================================
-- ÍNDICES PARA OPTIMIZAR CONSULTAS
-- =============================================

-- Usuarios por área
CREATE INDEX IX_Usuario_Area ON Usuario(id_area);

-- Casos por estado y fechas
CREATE INDEX IX_Caso_Estado ON Caso(estado);
CREATE INDEX IX_Caso_Fecha ON Caso(fecha_creacion);

-- Casos por áreas asignadas
CREATE INDEX IX_CasoArea_Caso ON CasoArea(id_caso);
CREATE INDEX IX_CasoArea_Area ON CasoArea(id_area);

-- Seguimientos por caso
CREATE INDEX IX_Seguimiento_Caso ON Seguimiento(id_caso);

-- Adjuntos por caso o seguimiento
CREATE INDEX IX_Adjunto_Caso ON Adjunto(id_caso);
CREATE INDEX IX_Adjunto_Seguimiento ON Adjunto(id_seguimiento);