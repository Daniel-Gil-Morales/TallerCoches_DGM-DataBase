
USE tallercoches_dgm:

-- CONSULTAS --------------------------------------------------------------------------------------------------------------

-- 1. Clientes y sus coches:

select c.nombre, c.apellido, co.marca, co.modelo
from clientes c
inner join coches co on c.id_cliente = co.id_cliente;


-- 2. Reparaciones realizadas por un empleado específico:

select r.id_reparacion, r.fecha, r.descripcion, e.nombre
from reparaciones r
inner join empleados e on r.id_empleado = e.id_empleado
where e.nombre = 'Lew';


-- 3. Obtener un reporte detallado que muestra el nombre de los clientes, la marca y modelo de los coches que poseen, las fechas de las reparaciones realizadas, 
--    los tipos de reparaciones efectuadas y las observaciones asociadas a cada reparación.

select clientes.nombre as nombre_cliente, coches.marca, coches.modelo, reparaciones.fecha as fecha_reparacion, tipos_reparaciones.nombre as tipo_reparacion, reparaciones_tipos_reparaciones.observaciones
from clientes
inner join coches on clientes.id_cliente = coches.id_cliente
inner join reparaciones on coches.id_coche = reparaciones.id_coche
inner join reparaciones_tipos_reparaciones on reparaciones.id_reparacion = reparaciones_tipos_reparaciones.id_reparacion
inner join tipos_reparaciones on reparaciones_tipos_reparaciones.id_tipo_reparacion = tipos_reparaciones.id_tipo_reparacion;


-- 4. Reparaciones y tipos de reparaciones asociadas:

select r.id_reparacion, r.fecha, t.nombre
from reparaciones r
inner join reparaciones_tipos_reparaciones rt on r.id_reparacion = rt.id_reparacion
inner join tipos_reparaciones t on rt.id_tipo_reparacion = t.id_tipo_reparacion;


-- 5. Empleados y el número de reparaciones realizadas por cada uno:

select e.nombre, e.apellido, count(r.id_reparacion)
from empleados e
inner join reparaciones r on e.id_empleado = r.id_empleado
group by e.id_empleado;


-- 6. informe detallado que presenta el nombre de los clientes, junto con la información de los coches que poseen, incluyendo marca y modelo. 

select clientes.nombre as nombre_cliente, coches.marca, coches.modelo, reparaciones.fecha as fecha_reparacion, tipos_reparaciones.nombre as tipo_reparacion, reparaciones_tipos_reparaciones.observaciones, pago.importe_pago, pago.fecha_pago
from clientes
inner join coches on clientes.id_cliente = coches.id_cliente
inner join reparaciones on coches.id_coche = reparaciones.id_coche
inner join reparaciones_tipos_reparaciones on reparaciones.id_reparacion = reparaciones_tipos_reparaciones.id_reparacion
inner join tipos_reparaciones on reparaciones_tipos_reparaciones.id_tipo_reparacion = tipos_reparaciones.id_tipo_reparacion
left join pago on reparaciones.id_reparacion = pago.id_reparacion;







-- VISTAS --------------------------------------------------------------------------------------------------------------

-- 1. Clientes y sus coches:

create view vista_clientes_coches as
select c.nombre, c.apellido, co.marca, co.modelo
from clientes c
inner join coches co on c.id_cliente = co.id_cliente;

select * from vista_clientes_coches;


-- 2. Reparaciones realizadas por un empleado específico:

create view vista_reparaciones_empleado as
select r.id_reparacion, r.fecha, r.descripcion, e.nombre as nombre_empleado
from reparaciones r
inner join empleados e on r.id_empleado = e.id_empleado
where e.nombre = 'Lew';

select * from vista_reparaciones_empleado;





-- FUNCIONES --------------------------------------------------------------------------------------------------------------

-- 1. Función que calcula el importe total de una reparación:

DROP FUNCTION IF EXISTS calcularImporteTotalReparacion;

CREATE FUNCTION calcularImporteTotalReparacion(reparacion_id INT) RETURNS DECIMAL(10,2)
DETERMINISTIC
BEGIN
    DECLARE total DECIMAL(10,2);
    SELECT SUM(importe_total) INTO total FROM reparaciones WHERE id_reparacion = reparacion_id;
    RETURN total;
END;

SELECT calcularImporteTotalReparacion(1);



-- 2. Función para contar el número de reparaciones de un empleado:

USE tallercoches_dgm;

drop function if exists contarReparacionesEmpleado;

DELIMITER $$
create function contarReparacionesEmpleado(empleado_id int) returns int 
DETERMINISTIC
BEGIN
    declare num_reparaciones int;
    select count(*) into num_reparaciones from reparaciones where id_empleado = empleado_id;
    return num_reparaciones;
END$$
DELIMITER ;

select contarReparacionesEmpleado(2);





-- PROCEDIMIENTOS --------------------------------------------------------------------------------------------------------------

-- 1. Procedimiento para registrar un nuevo pago:

drop procedure if exists registrarPago;
DELIMITER &&
create procedure registrarPago(in cliente_id int, in reparacion_id int, in importe_pago decimal(10,2), in fecha_pago date)
BEGIN
    insert into pago (id_cliente, id_reparacion, importe_pago, fecha_pago, estado_pago_total)
    values (cliente_id, reparacion_id, importe_pago, fecha_pago, 'pendiente');
END &&
DELIMITER ;

call registrarPago(1, 1, 100.00, '2024-05-14');

-- 2. Procedimiento para marcar una reparación como pagada:

drop procedure if exists marcarReparacionPagada;
DELIMITER &&
create procedure marcarReparacionPagada(in pago_id int)
BEGIN
    update pago set estado_pago_total = 'pagado' where id_pago = pago_id;
END &&
DELIMITER ;

call marcarReparacionPagada(1);

-- 3. Procedimiento que utiliza un cursor para mostrar las reparaciones pendientes de pago:

drop procedure if exists mostrarReparacionesPendientesPago;

DELIMITER $$
create procedure mostrarReparacionesPendientesPago()
BEGIN
    declare contador int default 0;
    declare total_registros int;
    declare reparacion_id int;
    declare descripcion_reparacion varchar(255);

    select count(*) into total_registros 
    from reparaciones 
    where id_reparacion not in (select id_reparacion from pago where estado_pago_total = 'pagado');

    create temporary table if not exists temp_reparaciones (
        id_reparacion int,
        descripcion varchar(255)
    );

    while contador < total_registros do
        select id_reparacion, descripcion 
        into reparacion_id, descripcion_reparacion
        from reparaciones 
        where id_reparacion not in (select id_reparacion from pago where estado_pago_total = 'pagado')
        limit contador, 1;

        insert into temp_reparaciones (id_reparacion, descripcion) 
        values (reparacion_id, descripcion_reparacion);

        set contador = contador + 1;
    end while;

    select * from temp_reparaciones;

    drop temporary table if exists temp_reparaciones;
END$$
DELIMITER ;

call mostrarReparacionesPendientesPago();





-- TRIGGERS --------------------------------------------------------------------------------------------------------------

-- 1. Este trigger calcula el importe de pago mensual antes de insertar una nueva fila en la tabla pago. Se basa en el campo plazo_pagos de la tabla reparaciones para determinar cuánto 
--    debe pagar el cliente mensualmente. Si el plazo de pago es diferente de mensual, calcula el importe de pago en función de ese plazo (trimestral, cuatrimestral, semestral o anual). 
--    Si el plazo no está especificado o es desconocido, asume que el pago es mensual.

DROP TRIGGER IF EXISTS calcular_importe_pago_mensual;
DELIMITER $$
CREATE TRIGGER calcular_importe_pago_mensual
BEFORE INSERT ON pago
FOR EACH ROW
BEGIN
    DECLARE importe_total DECIMAL(10, 2);

    IF NEW.id_reparacion IS NOT NULL THEN
        -- Seleccionar el plazo de pagos de la tabla reparaciones
        SELECT plazo_pagos, importe_total INTO @plazo_pagos, importe_total FROM reparaciones WHERE id_reparacion = NEW.id_reparacion;

        -- Calcular el importe de pago basado en el plazo de pagos
        CASE @plazo_pagos
            WHEN 'trimestral' THEN SET NEW.importe_pago = importe_total / 3;
            WHEN 'cuatrimestral' THEN SET NEW.importe_pago = importe_total / 4;
            WHEN 'semestral' THEN SET NEW.importe_pago = importe_total / 6;
            WHEN 'anual' THEN SET NEW.importe_pago = importe_total / 12;
            ELSE SET NEW.importe_pago = importe_total; -- Por defecto, asume plazo de pagos mensual
        END CASE;
    END IF;
END$$
DELIMITER ;


INSERT INTO reparaciones (id_reparacion, plazo_pagos, importe_total) VALUES
(1001, 'mensual', 100),
(1002, 'trimestral', 300),
(1003, 'semestral', 600);


-- Esto activará el trigger y calculará los importes de pago según el plazo de pagos de las reparaciones
INSERT INTO pago (id_reparacion) VALUES (1001), (1002), (1003);

SELECT * FROM pago;



-- 2. Este trigger se activará después de insertar un nuevo registro en la tabla pago. Calcula el importe total pagado para la reparación correspondiente y el importe total de la reparación desde 
--    la tabla reparaciones. Luego, actualiza el campo estado_pago_total en la tabla pago basado en si el total pagado es igual o mayor al importe total de la reparación.

DROP TRIGGER IF EXISTS actualizar_estado_pago;

DELIMITER $$
CREATE TRIGGER actualizar_estado_pago AFTER INSERT ON pago FOR EACH ROW
BEGIN
    DECLARE total_pagado DECIMAL(10,2);
    DECLARE total_reparacion DECIMAL(10,2);
    DECLARE estado_pago VARCHAR(10);
    
    -- Crear tabla temporal para calcular el estado de pago
    CREATE TEMPORARY TABLE IF NOT EXISTS temp_pago (
        id_reparacion INT,
        total_pagado DECIMAL(10,2),
        total_reparacion DECIMAL(10,2),
        estado_pago VARCHAR(10)
    );

    -- Obtener el importe total pagado para la reparación correspondiente
    SELECT SUM(importe_pago) INTO total_pagado FROM pago WHERE id_reparacion = NEW.id_reparacion;
    
    -- Obtener el importe total de la reparación
    SELECT importe_total INTO total_reparacion FROM reparaciones WHERE id_reparacion = NEW.id_reparacion;
    
    -- Definir el estado de pago
    IF total_pagado >= total_reparacion THEN
        SET estado_pago = 'pagado';
    ELSE
        SET estado_pago = 'pendiente';
    END IF;

    -- Insertar datos en la tabla temporal
    INSERT INTO temp_pago VALUES (NEW.id_reparacion, total_pagado, total_reparacion, estado_pago);
END$$
-- No se puede actualizar la tabla pago dentro de un trigger porque ya está siendo utilizada por la misma operación que activa el trigger.
-- Una forma de abordar este problema es utilizando una tabla temporal para calcular el estado de pago y luego actualizar la tabla pago fuera del trigger.
CREATE PROCEDURE actualizar_estado_pago()
BEGIN
    -- Actualizar el campo estado_pago_total en la tabla pago
    UPDATE pago p
    JOIN temp_pago tp ON p.id_reparacion = tp.id_reparacion
    SET p.estado_pago_total = tp.estado_pago;
    
    -- Eliminar la tabla temporal
    DROP TEMPORARY TABLE IF EXISTS temp_pago;

    -- Sentencia final para evitar el error de sintaxis
    SELECT 'Tabla temporal eliminada correctamente';
END$$

DELIMITER ;

INSERT INTO pago (id_reparacion, importe_pago, fecha_pago, estado_pago_total) VALUES (1, 100.00, '2024-05-14', 'pendiente');

-- Verificar la tabla temporal (temp_pago)
SELECT * FROM temp_pago;

-- Si es necesario, puedes ejecutar el procedimiento almacenado manualmente
CALL actualizar_estado_pago();

-- Verificar nuevamente la tabla pago para ver si los cambios se reflejaron correctamente
SELECT * FROM pago WHERE id_reparacion = 1;
