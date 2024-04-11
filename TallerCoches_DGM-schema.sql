drop database if exists TallerCoches_DGM;
create database if not exists TallerCoches_DGM;
use TallerCoches_DGM;

create table clientes (
    id_cliente int auto_increment primary key,
    nombre varchar(100),
    apellido varchar(100),
    telefono varchar(20),
    correo_electronico varchar(100),
    direccion varchar(255)
);

create table coches (
    id_coche int auto_increment primary key,
    marca varchar(100),
    modelo varchar(100),
    ano int,
    matricula varchar(20),
    id_cliente int,
    foreign key (id_cliente) references clientes(id_cliente)
);

create table empleados (
    id_empleado int auto_increment primary key,
    nombre varchar(100),
    apellido varchar(100),
    telefono varchar(20),
    correo_electronico varchar(100),
    cargo varchar(100)
);

create table reparaciones (
    id_reparacion int auto_increment primary key,
    fecha date,
    id_coche int,
    id_empleado int,
    descripcion text,
    costo decimal(10, 2),
    foreign key (id_coche) references coches(id_coche),
    foreign key (id_empleado) references empleados(id_empleado)
);

create table tipos_reparaciones (
    id_tipo_reparacion int auto_increment primary key,
    nombre varchar(100),
    descripcion text
);

create table reparaciones_tipos_reparaciones (
    id_reparacion int,
    id_tipo_reparacion int,
    observaciones varchar(200),
    fecha date,
    foreign key (id_reparacion) references reparaciones(id_reparacion),
    foreign key (id_tipo_reparacion) references tipos_reparaciones(id_tipo_reparacion),
    primary key (id_reparacion, id_tipo_reparacion)
);

CREATE TABLE Pago (
    id_pago INT AUTO_INCREMENT PRIMARY KEY,
    id_cliente INT,
    id_reparacion INT,
    cantidad_pagada DECIMAL(10, 2),
    fecha_pago DATE,
    FOREIGN KEY (id_cliente) REFERENCES clientes(id_cliente),
    FOREIGN KEY (id_reparacion) REFERENCES reparaciones(id_reparacion)
);



