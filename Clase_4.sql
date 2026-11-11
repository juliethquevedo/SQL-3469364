/*1. Inserte 3 proveedores y asiguelos con UPDATE*/
INSERT INTO proveedores(nit,razon_social,telefono,email,ciudad,activo) VALUES
('900111222-1','TecnoMagix SAS','3101110001', 'tecnomagix@correo.com','Bogota',1),
('900222333-2','HogarCleaner Ltda','3102220002', 'hogarcleaner@correo.com','Medellin',1),
('900333444-3','Papeleria SAS','3103330003', 'maquinapapelera@correo.com','Cali',1);

UPDATE productos SET id_proveedor = 1 WHERE id_categoria = (SELECT id_categoria FROM categorias WHERE nombre = 'Tecnología');
UPDATE productos SET id_proveedor = 2 WHERE id_categoria = (SELECT id_categoria FROM categorias WHERE nombre = 'Hogar');
UPDATE productos SET id_proveedor = 3 WHERE id_categoria = (SELECT id_categoria FROM categorias WHERE nombre = 'Papelería');
/*CONSULTA DE TODO*/
SELECT*FROM productos;
SELECT*FROM proveedores;

/*2. TODOS los productos con categoria y proveedor*/
SELECT p.nombre AS productos, c.nombre AS categoria, pr.razon_social AS proveedores
FROM productos p
LEFT JOIN categorias c ON p.id_categoria = c.id_categoria
LEFT JOIN proveedores pr ON p.id_proveedor = pr.id_proveedor;

/*3. Total vendido por ciudad del cliente (sin cancelados)*/
SELECT c.ciudad_residencia,p.estado AS estado SUM(dp.cantidad * dp.precio_unitario) AS total_vendido
FROM pedidos p
INNER JOIN clientes c ON p.id_cliente = c.id_cliente
INNER JOIN detalle_pedidos dp ON p.id_pedido = dp.id_pedido
WHERE p.estado <> 'CANCELADO'
GROUP BY c.ciudad_residencia
ORDER BY total_vendido DESC;

/*4. Producto con más unidades vendidas (con filtro de cancelados)*/
SELECT p.nombre, SUM(dp.cantidad) AS unidades_vendidas
FROM productos p
JOIN detalle_pedidos dp ON p.id_producto = dp.id_producto
JOIN pedidos pe ON pe.id_pedido = dp.id_pedido
WHERE pe.estado <> 'CANCELADO'
GROUP BY p.id_producto, p.nombre
ORDER BY unidades_vendidas DESC
LIMIT 1;

/*5. Clientes cuyo total > promedio por cliente (subconsulta en HAVING)*/
SELECT CONCAT(cl.nombre, ' ', cl.apellidos) AS cliente, SUM(pe.total) AS total_comprado
FROM clientes cl
INNER JOIN pedidos pe ON pe.id_cliente = cl.id_cliente
WHERE pe.estado <> 'CANCELADO'
GROUP BY cl.id_cliente, cl.nombre, cl.apellidos
HAVING total_comprado > (
    SELECT ROUND(AVG(t.total_cliente),2) FROM (
        SELECT id_cliente, SUM(total) AS total_cliente FROM pedidos WHERE estado <> 'CANCELADO' GROUP BY id_cliente
    ) AS t
);

/*6. Categorías de las que NO se ha vendido ningún producto (NOT EXISTS)*/
SELECT 
    c.nombre AS categoria, 
    p.nombre AS producto, 
    'NO VENDIDO' AS estado
FROM categorias c
INNER JOIN productos p ON p.id_categoria = c.id_categoria
WHERE NOT EXISTS (
    SELECT 1 FROM productos p2
    INNER JOIN detalle_pedidos d ON d.id_producto = p2.id_producto
    INNER JOIN pedidos pe ON pe.id_pedido = d.id_pedido
    WHERE p2.id_categoria = c.id_categoria 
    AND p2.id_producto = p.id_producto
    AND pe.estado <> 'CANCELADO'
);

/*7. Transacción +10% Papelería con ROLLBACK*/
START TRANSACTION;
UPDATE productos SET precio = precio * 1.10 WHERE id_categoria = (SELECT id_categoria FROM categorias WHERE nombre = 'Papelería');
SELECT p.nombre AS producto, p.precio AS precio_actualizado 
FROM productos p JOIN categorias c ON c.id_categoria = p.id_categoria WHERE c.nombre = 'Papelería';
/*Deshacer cambios*/
ROLLBACK;
SELECT p.nombre AS producto, c.nombre AS categoria, p.precio AS precio_actualizado
FROM productos p JOIN categorias c ON c.id_categoria = p.id_categoria WHERE c.nombre = 'Papeleria';
/*8. Elimine pedidos CANCELADOS y verifique CASCADE*/
-- Ver antes
SELECT id_pedido FROM pedidos WHERE estado = 'CANCELADO';
SELECT COUNT(*) AS total_detalles_antes FROM detalle_pedidos;

DELETE FROM pedidos WHERE estado = 'CANCELADO';

-- Ver después (debe dar 0 cancelados y menos detalles)
SELECT id_pedido FROM pedidos WHERE estado = 'CANCELADO';
SELECT COUNT(*) AS total_detalles_despues FROM detalle_pedidos;
/*(LA CONSULTA)*/
/* Ver productos cancelados */
SELECT p.id_pedido, pr.nombre AS producto, p.estado 
FROM pedidos p 
JOIN detalle_pedidos d ON d.id_pedido = p.id_pedido 
JOIN productos pr ON pr.id_producto = d.id_producto 
WHERE p.estado = 'CANCELADO';

/* Eliminar en cascada */
DELETE FROM pedidos WHERE estado = 'CANCELADO';

/* Ver que ya no existen */
SELECT * FROM pedidos WHERE estado = 'CANCELADO';
SELECT COUNT(*) FROM detalle_pedido