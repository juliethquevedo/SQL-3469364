/*  3. CONSULTAS BÁSICAS (la "R" de CRUD: Read)*/

-- 3.1 Columnas específicas con ALIAS (AS) para nombrarlas mejor
SELECT nombre AS producto, precio AS precio_venta, stock AS unidades
FROM productos;

-- 3.2 WHERE con operadores de comparación y lógicos (AND / OR / NOT)
SELECT nombre, precio, stock
FROM productos
WHERE precio > 100000 AND stock >= 20;

-- 3.3 BETWEEN (rango, incluye los extremos)
SELECT nombre, precio FROM productos
WHERE precio BETWEEN 20000 AND 200000;

-- 3.4 IN (lista de valores)
SELECT nombres, apellidos, ciudad FROM clientes
WHERE ciudad IN ('Medellín', 'Bogotá');

-- 3.5 LIKE: % = cualquier cantidad de caracteres, _ = exactamente un carácter
SELECT nombres, apellidos, email FROM clientes
WHERE apellidos LIKE 'R%'; -- apellidos que empiezan por R

-- 3.6 IS NULL / IS NOT NULL (¡NULL no se compara con =!)
SELECT nombres, apellidos FROM clientes
WHERE telefono IS NULL;

-- 3.7 ORDER BY (ASC ascendente por defecto, DESC descendente) y LIMIT
SELECT nombre, precio FROM productos
ORDER BY precio DESC
LIMIT 3; -- los 3 productos más caros

-- 3.8 DISTINCT: valores sin repetir
SELECT DISTINCT ciudad FROM clientes ORDER BY ciudad;

-- 3.9 Columnas calculadas y funciones de texto
SELECT CONCAT(nombres, ' ', apellidos) AS cliente_completo,
       UPPER(ciudad) AS ciudad_mayuscula,
       CHAR_LENGTH(email) AS largo_email
FROM clientes;

-- 3.10 CASE: lógica condicional dentro de la consulta
SELECT nombre, stock,
    CASE
        WHEN stock < 20 THEN 'Stock bajo'
        WHEN stock < 100 THEN 'Stock medio'
        ELSE 'Stock alto'
    END AS nivel_stock
FROM productos;

/* 4. JOINs - CONSULTAR VARIAS TABLAS RELACIONADAS
   INNER JOIN -> solo las filas que tienen pareja en ambas tablas
   LEFT JOIN -> todas las de la izquierda + las parejas (o NULL)
    RIGHT JOIN -> todas las de la derecha + las parejas (o NULL)
    FULL JOIN -> todas las de ambas (MySQL no lo tiene: se emula con UNION)
Se usan alias cortos (p, c...) para no repetir el nombre de la tabla.*/

-- 4.1 INNER JOIN: productos con el nombre de su categoría
SELECT p.nombre AS producto, c.nombre AS categoria, p.precio
FROM productos p
INNER JOIN categorias c ON c.id_categoria = p.id_categoria
ORDER BY c.nombre, p.nombre;

-- 4.2 INNER JOIN: pedidos con el nombre del cliente
SELECT pe.id_pedido, pe.fecha_pedido, pe.estado, pe.total,
       CONCAT(cl.nombre, ' ', cl.apellidos) AS cliente
FROM pedidos pe
INNER JOIN clientes cl ON cl.id_cliente = pe.id_cliente
ORDER BY pe.fecha_pedido;

-- 4.3 JOIN de 4 tablas: la "factura" detallada de cada pedido
SELECT pe.id_pedido,
       CONCAT(cl.nombre, ' ', cl.apellidos) AS cliente,
       pr.nombre AS producto,
       d.cantidad,
       d.precio_unitario,
       d.cantidad * d.precio_unitario AS subtotal
FROM pedidos pe
INNER JOIN clientes cl ON cl.id_cliente = pe.id_cliente
INNER JOIN detalle_pedidos d ON d.id_pedido = pe.id_pedido
INNER JOIN productos pr ON pr.id_producto = d.id_producto
ORDER BY pe.id_pedido, pr.nombre;

-- 4.4 LEFT JOIN: TODOS los clientes, tengan o no pedidos
SELECT cl.nombre, cl.apellidos, pe.id_pedido, pe.total
FROM clientes cl
LEFT JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
ORDER BY cl.id_cliente;

-- 4.5 LEFT JOIN + IS NULL: clientes que NUNCA han comprado
SELECT cl.nombre, cl.apellidos, cl.ciudad_residencia
FROM clientes cl
LEFT JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
WHERE pe.id_pedido IS NULL; -- Resultado esperado: Mateo

-- 4.6 LEFT JOIN + IS NULL: productos que nunca se han vendido
SELECT pr.nombre, pr.stock
FROM productos pr
LEFT JOIN detalle_pedidos d ON d.id_producto = pr.id_producto
WHERE d.id_detalle IS NULL; -- Resultado esperado: Bicicleta estática

-- 4.7 RIGHT JOIN: todas las categorías aunque no tengan productos
SELECT c.nombre AS categoria, p.nombre AS producto
FROM productos p
RIGHT JOIN categorias c ON c.id_categoria = p.id_categoria
ORDER BY c.nombre; -- Juguetes aparece con producto NULL

-- 4.8 FULL OUTER JOIN emulado (LEFT JOIN UNION RIGHT JOIN)
SELECT c.nombre AS categoria, p.nombre AS producto
FROM categorias c LEFT JOIN productos p ON p.id_categoria = c.id_categoria
UNION
SELECT c.nombre, p.nombre
FROM categorias c RIGHT JOIN productos p ON p.id_categoria = c.id_categoria;

/*  5. FUNCIONES DE AGREGACIÓN, GROUP BY y HAVING
   COUNT, SUM, AVG, MIN, MAX resumen muchas filas en un solo valor.
   GROUP BY -> agrupa las filas para calcular el resumen por grupo.
   HAVING -> filtra GRUPOS (WHERE filtra filas ANTES de agrupar).
   Regla: toda columna del SELECT que no esté en una función de
   agregación debe ir en el GROUP BY. */

-- 5.1 Resumen general de productos
SELECT COUNT(*) AS total_productos,
       SUM(stock) AS unidades_en_bodega,
       ROUND(AVG(precio), 2) AS precio_promedio,
       MIN(precio) AS precio_minimo,
       MAX(precio) AS precio_maximo
FROM productos;

-- 5.2 Cantidad de productos y valor del inventario por categoría
SELECT c.nombre AS categoria,
       COUNT(p.id_producto) AS cantidad_productos,
       SUM(p.precio * p.stock) AS valor_inventario
FROM categorias c
LEFT JOIN productos p ON p.id_categoria = c.id_categoria
GROUP BY c.nombre
ORDER BY valor_inventario DESC;

-- 5.3 Total comprado por cliente (sin pedidos cancelados)
SELECT CONCAT(cl.nombre, ' ', cl.apellidos) AS cliente,
       COUNT(pe.id_pedido) AS numero_pedidos,
       SUM(pe.total) AS total_comprado
FROM clientes cl
INNER JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
WHERE pe.estado <> 'CANCELADO' 
GROUP BY cl.id_cliente, cl.nombre, cl.apellidos
ORDER BY total_comprado DESC;

-- 5.4 HAVING: clientes que han comprado más de 1.000.000
SELECT CONCAT(cl.nombre, ' ', cl.apellidos) AS cliente,
       SUM(pe.total) AS total_comprado
FROM clientes cl
INNER JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
WHERE pe.estado <> 'CANCELADO'
GROUP BY cl.id_cliente, cl.nombre, cl.apellidos
HAVING SUM(pe.total) > 1000000; -- HAVING: filtra los grupos

-- 5.5 Ventas por mes
SELECT DATE_FORMAT(fecha_pedido, '%Y-%m') AS mes,
       COUNT(*) AS pedidos,
       SUM(total) AS ventas
FROM pedidos
WHERE estado <> 'CANCELADO'
GROUP BY DATE_FORMAT(fecha_pedido, '%Y-%m')
ORDER BY mes;

-- 5.6 Unidades vendidas por producto
SELECT pr.nombre, SUM(d.cantidad) AS unidades_vendidas
FROM detalle_pedidos d
INNER JOIN productos pr ON pr.id_producto = d.id_producto
INNER JOIN pedidos pe ON pe.id_pedido = d.id_pedido
WHERE pe.estado <> 'CANCELADO'
GROUP BY pr.id_producto, pr.nombre
ORDER BY unidades_vendidas DESC;

-- 5.7 Pedidos por estado
SELECT estado, COUNT(*) AS cantidad, SUM(total) AS valor
FROM pedidos
GROUP BY estado;

/* Subconsultas una consulta dentro de otra*/
--6. Subconsultas en where (valor unico)productos mas caros que el promedio
SELECT nombre,precio
FROM productos
WHERE precio > (SELECT AVG (precio)FROM productos);
--Subconsultas con IN (lista)clientes que han hecho al menos un pedido
SELECT nombre, apellidos
FROM clientes
WHERE id_cliente IN(SELECT id_cliente FROM pedidos);
--NOT EXISTS: categorias que no tienen productos
SELECT c.nombre
FROM categorias c
WHERE NOT EXISTS (SELECT 1 FROM productos p WHERE p.id_categoria = c.id_categoria);
--Subconsultas escalar en el select : numero de pedidos de cada cliente
SELECT cl.nombre, cl.apellidos,
(SELECT COUNT(*)FROM pedidos pe WHERE pe.id_cliente=cl.id_cliente)AS cantidad_pedidos 
FROM clientes cl;
--Subconsulta  en from (tabla derivado) promedio de compra por cliente 
SELECT ROUND(AVG(t.total_cliente), 2) 
AS promedio_compra_por_cliente
FROM (SELECT id_cliente, SUM(total) AS total_cliente
FROM pedidos
WHERE estado <> 'CANCELADO'
GROUP BY id_cliente) AS t;
--En mysql una tabla derivada necesita un alias en este caso"t" y 
--no se puede usar el alias en la misma consulta, por eso se hace una subconsulta en from

--Subconsulta correlacionada productos mas caros que el promedio de su categoria
SELECT p.nombre, p.precio, p.id_categoria
FROM productos p
WHERE p.precio > (SELECT AVG(p2.precio)
FROM productos p2
WHERE p2.id_categoria = p.id_categoria);

--Subconsulta el pedido de mayor valor con MAX
SELECT id_pedido, id_cliente, total
FROM pedidos
WHERE total = (SELECT MAX(total) FROM pedidos);

/* CRUD COMPLETO + TRANSACCIONES
 Una transaccion agrupa varias sentencias en una sola
unidad o se guardan TODAS en un commit o no se guarda
ninguna ROLLBACK
 propiedades: ACID: Atomicidad, Consistencia,
Aislamineto, Durabilidad */

-- C = create registrar un cliente nuevo
INSERT INTO clientes (tipo_documento,
numero_documento, nombre, apellidos, email, telefono,
ciudad_residencia)
VALUES ('CC', '1009009009', 'Sofia', 'Cardona Mejia',
'sofia.cardona@correo.com', '3109990000', 'Manizales');

-- R = Read consultarlo
SELECT * FROM clientes WHERE numero_documento = 
'1009009009';

-- U = UPDATE modificar un cliente existente
UPDATE clientes
SET telefono = '3201234567',
ciudad_residencia = 'Armenia'
WHERE numero_documento = '1009009009';

SELECT * FROM clientes WHERE numero_documento = '1009009009';

--DELETE Eliminar siempre con WHERE por que sin WHERE elimina toda la tabla
DELETE FROM clientes WHERE numero_documento = '1009009009';

--transacciones: con rollback simulados una venta y nos arrepentimos de la venta y no se guarda nada en la base de datos
START TRANSACTION;
INSERT INTO pedidos (id_cliente, estado) VALUES (8, 'PENDIENTE');
SET @nuevo_pedido_id = LAST_INSERT_ID();--ID GENERADO por el ultimo insert

INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario)
VALUES (@nuevo_pedido_id, 12, 1, 1200000);
UPDATE productos SET stock = stock -1 WHERE id_producto = 12;

SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido_id;
--dentro de la transaccion se puede consultar lo que se ha hecho pero no se ve desde afuera 
ROLLBACK ; -- deshaceer la transaccion y no se guarda nada en la base de datos

SELECT * FROM pedidos WHERE id_pedido = @nuevo_pedido;

--ya no existe

SELECT stock FROM productos WHERE id_producto =12;

--el stock debe seguir en 5

START TRANSACTION
UPDATE productos
SET precio = ROUND(precio*1.05,0)
WHERE id_categoria = (SELECT id_categoria FROM categorias WHERE nombre = 'Deportes');
COMMIT;
--confirma el cambio de forma permanente
SELECT nombre, precio FROM productos WHERE id_categoria = 4;

--DELETE en cascada: al borrar un pedido se borran sus detalles
INSERT INTO pedidos (id_cliente, estado)
VALUES (8, 'Pendiente');

SET @pedido_tem = LAST_INSERT_ID();

INSERT INTO detalle_pedidos (id_pedido, id_producto, cantidad, precio_unitario)
VALUES (@pedido_tem, 2, 1, 45000);

SELECT COUNT(*) AS detalles_antes FROM detalle_pedidos 
WHERE id_pedido = @pedido_tem;--1
DELETE FROM pedidos WHERE id_pedido = @pedido_tem; 
SELECT COUNT(*) AS detalle_despues FROM detalle_pedidos WHERE id_pedido = @pedido_tem;--0