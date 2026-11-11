
Si quieres borrar los registros de las dos tablas para volver a ejecutar tus INSERT, hazlo en este orden: primero los detalles y después los pedidos.

sql
DELETE FROM detalle_pedidos;
DELETE FROM pedidos;

Esto elimina los registros de ambas tablas y, a diferencia de TRUNCATE, permite respetar las relaciones entre claves foráneas.

Si también quieres reiniciar los contadores AUTO_INCREMENT, puedes ejecutar:

sql
ALTER TABLE detalle_pedidos AUTO_INCREMENT = 1;
ALTER TABLE pedidos AUTO_INCREMENT = 1;