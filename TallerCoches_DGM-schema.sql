DROP DATABASE IF EXISTS tallercoches_dgm;
CREATE DATABASE tallercoches_dgm;
USE tallercoches_dgm;

create table clientes (
    id_cliente int auto_increment primary key,
    nombre varchar(100),
    apellido varchar(100),
    telefono varchar(20) unique,
    correo_electronico varchar(100) unique,
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
    telefono varchar(20) unique,
    correo_electronico varchar(100) unique,
    cargo enum('mecanico raso', 'mecanico superior', 'tester')
);

create table reparaciones (
    id_reparacion int auto_increment primary key,
    fecha date,
    id_coche int,
    id_empleado int,
    descripcion text,
    importe_total decimal(10, 2),
    plazo_pagos enum('contado', 'mensual', 'trimestral', 'cuatrimestral', 'semestral', 'anual'),
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

create table pago (
    id_pago int auto_increment primary key,
    id_cliente int,
    id_reparacion int,
    importe_pago decimal(10, 2),
    fecha_pago date,
    estado_pago_total enum('pagado', 'pendiente'),
    foreign key (id_cliente) references clientes(id_cliente),
    foreign key (id_reparacion) references reparaciones(id_reparacion)
);
