
use tallercoches_dgm:

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
where e.nombre = 'nombre del empleado';

select * from vista_reparaciones_empleado;






-- FUNCIONES --------------------------------------------------------------------------------------------------------------

-- 1. Función que calcula el importe total de una reparación:

drop function if exists calcularImporteTotalReparacion;
DELIMITER &&
create function calcularImporteTotalReparacion(reparacion_id int) returns decimal(10,2)
BEGIN
    declare total decimal(10,2);
    select sum(importe_total) into total from reparaciones where id_reparacion = reparacion_id;
    return total;
end &&
DELIMITER ;


-- 2. Función para contar el número de reparaciones de un empleado:

drop function if exists contarReparacionesEmpleado;
DELIMITER &&
create function contarReparacionesEmpleado(empleado_id int) returns int
BEGIN
    declare num_reparaciones int;
    select count(*) into num_reparaciones from reparaciones where id_empleado = empleado_id;
    return num_reparaciones;
END &&
DELIMITER ;






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


-- 2. Procedimiento para marcar una reparación como pagada:

drop procedure if exists marcarReparacionPagada;
DELIMITER &&
create procedure marcarReparacionPagada(in pago_id int)
BEGIN
    update pago set estado_pago_total = 'pagado' where id_pago = pago_id;
END &&
DELIMITER ;


-- 3. Procedimiento que utiliza un cursor para mostrar las reparaciones pendientes de pago:

drop procedure if exists mostrarReparacionesPendientesPago;
DELIMITER &&
create procedure mostrarReparacionesPendientesPago()
BEGIN
    declare done int default false;
    declare reparacion_id int;
    declare cur cursor for select id_reparacion from reparaciones where id_reparacion not in (select id_reparacion from pago where estado_pago_total = 'pagado');
    declare continue handler for not found set done = true;

    open cur;
    read_loop: loop
        fetch cur into reparacion_id;
        if done then
            leave read_loop;
        end if;
        select * from reparaciones where id_reparacion = reparacion_id;
    end loop;
    close cur;
END &&
DELIMITER ;






-- TRIGGERS --------------------------------------------------------------------------------------------------------------

-- 1. Este trigger calcula el importe de pago mensual antes de insertar una nueva fila en la tabla pago. Se basa en el campo plazo_pagos de la tabla reparaciones para determinar cuánto 
--    debe pagar el cliente mensualmente. Si el plazo de pago es diferente de mensual, calcula el importe de pago en función de ese plazo (trimestral, cuatrimestral, semestral o anual). 
--    Si el plazo no está especificado o es desconocido, asume que el pago es mensual.

drop trigger if exists calcular_importe_pago_mensual;
DELIMITER &&
create trigger calcular_importe_pago_mensual
before insert on pago
for each row
begin
    declare importe_total decimal(10, 2);
    if new.id_reparacion is not null then
        select costo into importe_total from reparaciones where id_reparacion = new.id_reparacion;
        if new.plazo_pagos = 'mensual' then
            set new.importe_pago = importe_total;
        elseif new.plazo_pagos = 'trimestral' then
            set new.importe_pago = importe_total / 3;
        elseif new.plazo_pagos = 'cuatrimestral' then
            set new.importe_pago = importe_total / 4;
        elseif new.plazo_pagos = 'semestral' then
            set new.importe_pago = importe_total / 6;
        elseif new.plazo_pagos = 'anual' then
            set new.importe_pago = importe_total / 12;
        else
            set new.importe_pago = importe_total;
        end if;
    end if;
end&&
DELIMITER ;


-- Este trigger se activará después de insertar un nuevo registro en la tabla pago. Calcula el importe total pagado para la reparación correspondiente y el importe total de la reparación desde 
-- la tabla reparaciones. Luego, actualiza el campo estado_pago_total en la tabla pago basado en si el total pagado es igual o mayor al importe total de la reparación.

DELIMITER //

CREATE TRIGGER actualizar_estado_pago AFTER INSERT ON pago FOR EACH ROW
BEGIN
    DECLARE total_pagado DECIMAL(10,2);
    DECLARE total_reparacion DECIMAL(10,2);
    
    -- Obtener el importe total pagado para la reparación correspondiente
    SELECT SUM(importe_pago) INTO total_pagado FROM pago WHERE id_reparacion = NEW.id_reparacion;
    
    -- Obtener el importe total de la reparación
    SELECT importe_total INTO total_reparacion FROM reparaciones WHERE id_reparacion = NEW.id_reparacion;
    
    -- Actualizar el campo estado_pago_total en la tabla pago
    IF total_pagado >= total_reparacion THEN
        UPDATE pago SET estado_pago_total = 'pagado' WHERE id_reparacion = NEW.id_reparacion;
    ELSE
        UPDATE pago SET estado_pago_total = 'pendiente' WHERE id_reparacion = NEW.id_reparacion;
    END IF;
END //

DELIMITER ;
