/* el DML nos permite manipular los datos en 4 acciones
crea, consulta, modificar, eliminar
Realizar consultas con select con filtros orden y limites
joins (Inner, left, right, full emulado)
agregaciones count sum avs sin max group by, having subconsultas
insertar datos de prueba y verificar que existen
DML= Lenguaje de manipulacion de datos
*/

/* Insertar datos de prueba (CRUD - C = crear)
si se insertan datos en una tabla se debe tener en 
cuenta el orden de los campos, el tipo de campos y la llave foranea
*/
INSERT INTO categorias (nombre, descripcion)
VALUES ('Tecnologia','Computadores,perifericos,accesorios');

INSERT INTO categorias (nombre, descripcion)
VALUES ('Hogar','Electrodomesticos y articulos para el hogar'),
('Papeleria', 'utiles escolares y oficina'),
('Deportes', 'Implementos deportivos'),
('Juguetes', 'Categoria nueva, aun sin productos');

/* Insertar datos en tabla relacion
*/
INSERT INTO productos (id_categoria, nombre, precio, stock) VALUES
(1, 'Portatil lenovo ideapad', 2500000, 15),
(1, 'Mouse inalambrico', 45000, 120),
(1, 'Teclado mecanico', 180000, 40),
(1, 'Monitor 24 pulgadas', 650000, 25),
(2, 'Licuadora Oster', 220000, 30),
(2, 'Juego de ollas', 310000, 18),
(2, 'Lampara led', 60000, 75),
(3, 'Cuaderno 100 hojas', 8500, 500),
(3, 'Resma de papel carta', 22000, 200),
(3, 'Kit de marcadores', 15000, 150),
(4, 'Balon de futbol', 85000, 60),
(4, 'Bicicleta estatica', 1200000, 5);

-- CLASE 2 - INSERTAR CLIENTES

INSERT INTO clientes (tipo_documento, numero_documento, nombre, apellidos, email, telefono, ciudad_residencia) VALUES
('CC', '1001001001', 'Ana Maria', 'Gomez Ruiz', 'ana.gomez@correo.com', '3001112233', 'Medellin'),
('CC', '1002002002', 'Carlos Andres', 'Perez Diaz', 'carlos.perez@correo.com', '3002223344', 'Bogota'),
('CC', '1003003003', 'Luisa Fernanda', 'Martinez Rios', 'luisa.martinez@correo.com', '3023334455', 'Cali'),
('TI', '1004004004', 'Juan David', 'Restrepo Toro', 'juan.restrepo@correo.com', '3034445566', 'Medellin'),
('CE', '1005005005', 'Valentina', 'Herrera Lopez', 'valentina.herrera@correo.com', '3045556677', 'Barranquilla'),
('CC', '1006006006', 'Santiago', 'Ramirez Castro', 'santiago.ramirez@correo.com', '3056667788', 'Bogota'),
('CC', '1007007007', 'Daniela', 'Ospina Vargas', 'daniela.ospina@correo.com', '3066677888', 'Medellin'),
('CC', '1008008008', 'Mateo', 'Londoño Giraldo', 'mateo.londoño@correo.com', null, 'Pereira');

INSERT INTO pedidos (id_cliente, fecha_pedido, estado)
VALUES
(1, '2026-08-01 10:15:00', 'Pagado'),
(2, '2026-08-03 14:30:00', 'Enviado'),
(1, '2026-08-10 09:00:00', 'Enviado'),
(3, '2026-08-15 16:45:00', 'Pagado'),
(4, '2026-08-20 11:20:00', 'Cancelado'),
(5, '2026-09-02 08:10:00', 'Pendiente'),
(6, '2026-09-05 19:00:00', 'Pagado'),
(2, '2026-09-12 12:00:00', 'Pagado'),
(7, '2026-09-20 17:30:00', 'Enviado'),
(3, '2026-09-28 10:05:00', 'Pendiente');
/* ajuste tabla pedidos*/
ALTER TABLE pedidos MODIFY COLUMN total DECIMAL (12,2) NOT NULL
DEFAULT 0;

ALTER TABLE pedidos DROP CONSTRAINT IF EXISTS ck_pedidos_total;
ALTER TABLE pedidos ADD CONSTRAINT ck_pedidos_total CHECK(total>=0);

INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario) 
VALUES
(1, 1, 1, 2500000),(1, 2, 2, 45000),
(2, 4, 2, 650000),(2, 3, 1, 45000),
(3, 8, 10, 8500),(3, 9, 2, 45000),
(4, 5, 1, 220000),(4, 7, 2, 60000),
(5, 11, 1, 85000),
(6, 6, 1, 3100000),(6, 2, 2, 45000),
(7, 1, 1, 2500000),(7, 4, 1, 650000),(7, 2, 1, 45000),
(8, 10, 5, 15000),(8, 8, 20, 8500),
(9, 3, 2, 180000),(9, 7, 1, 60000),
(10, 11, 2, 2500000),(10, 9, 3, 22000);

/* Trabajo con los datos de una base dre datos*/
/* Calcular el total de cada pedido con un UPDATE + consultas correlacionada
Para cada pedido "p" suma cantidad * precio de detalles */
UPDATE pedidos p
SET p.total=(SELECT sum(d.cantidad * d.
precio_unitario)
FROM detalle_pedidos d
WHERE d.id_pedido = p.id_pedido);

SELECT id_pedido, id_cliente, estado, total FROM 
pedidos;
/* 
CONSULTAS BASICAS READ DE UNA BASE DE DATOS 
1. Columnas especificas con alias AS para nombrarlas mejor */

SELECT nombre AS producto, precio AS precio_venta, stock AS unidades FROM productos;

/* where con operadores de comparacion y logicos AND OR NOT */
SELECT nombre, precio, stock
FROM productos
WHERE precio >100000 AND stock >= 20;

--BETWEEN (rango, incluye los extremos)
SELECT nombre, precio FROM productos
WHERE precio BETWEEN 20000 AND 200000;
