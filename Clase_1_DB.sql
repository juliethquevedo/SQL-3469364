/*
DDL= Lenguaje de definicion de datos
son los datos que nos permiten crear, modificar,
eliminar y consultar la estructura de la base de datos 
no los datos que se registre en ella
-create crear base de datos 
-alter modificar a estructura de las tablas de la base de datis
-drop eliminar base de datos o tablas
-truncate vaciar una tbla de datos y reinicia el contador de autoincremento
-rename cambiar el nombre de una tabla
*/

--Eliminar base de datos si existe con todo su contenido
DROP DATABASE IF EXISTS tienda_adso;
--Crear base de datos 
CREATE DATABASE tienda_adso 
CHARACTER SET utf8mb4 
COLLATE utf8mb4_unicode_ci;
--Utilizar la base de datos creada
USE tienda_adso;
--Crear BASE DE DATOS
CREATE TABLE categorias ( 
    id_categoria INT NOT NULL AUTO_INCREMENT,
    nombre VARCHAR (50) NOT NULL,
    descripcion VARCHAR (255) NULL,
    CONSTRAINT pk_categorias PRIMARY KEY (id_categoria),
    CONSTRAINT uq_categorias_nombre UNIQUE(nombre)
)ENGINE = InnoDB;

CREATE TABLE productos(
    id_producto INT NOT NULL AUTO_INCREMENT,
    id_categoria INT NOT NULL,
    nombre VARCHAR (100) NOT NULL,
    precio DECIMAL (12,2)NOT NULL,
    stock INT NOT NULL DEFAULT 0,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_productos PRIMARY KEY (id_producto),
    CONSTRAINT ck_productos_precio CHECK (precio > 0),
    CONSTRAINT ck_productos_stock CHECK (stock >= 0),

    CONSTRAINT fk_productos_categorias FOREIGN KEY (id_categoria)
    REFERENCES categorias (id_categoria)
    ON DELETE RESTRICT
    ON UPDATE CASCADE
    ) ENGINE = InnoDB;


  CREATE TABLE clientes (
    id_cliente INT NOT NULL AUTO_INCREMENT,
   tipo_documento VARCHAR (2) NOT NULL DEFAULT 'CC',
    numero_documento VARCHAR (20) NOT NULL,
     nombre VARCHAR (60) NOT NULL,
     apellidos VARCHAR (60) NOT NULL,
     email VARCHAR (100) NOT NULL,
      telefono VARCHAR (20) NOT NULL,
     ciudad VARCHAR (20) NOT NULL,
     fecha_registro DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
     CONSTRAINT pk_clientes PRIMARY KEY (id_cliente),
    CONSTRAINT uq_clientes_documento UNIQUE(numero_documento),
     CONSTRAINT uq_clientes_email UNIQUE(email),
    --campo disponible para tipo de documento, solo se permiten los valores CC, TI, CE y PASS
    CONSTRAINT ck_clientes_tipo_documento CHECK (tipo_documento IN ('CC','TI','CE','PASS')),
)ENGINE = InnoDB;
--Tabla pedidos
CREATE TABLE pedidos (
    id_pedido INT NOT NULL AUTO_INCREMENT,
 id_cliente INT NOT NULL,
    fecha_pedido DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
     estado VARCHAR (20) NOT NULL DEFAULT 'Pendiente',
  total VARCHAR(60) NOT NULL DEFAULT 0,
     CONSTRAINT pk_pedidos PRIMARY KEY (id_pedido),
    CONSTRAINT ck_pedidos_estado CHECK (estado IN ('Pendiente','Pagado','Enviado','Cancelado')),
     CONSTRAINT ck_pedidos_total CHECK (total > 0),
   CONSTRAINT fk_pedidos_clientes FOREIGN KEY (id_cliente)
      REFERENCES clientes (id_cliente)
      ON DELETE RESTRICT
      ON UPDATE CASCADE
)ENGINE = InnoDB;
--Tabla detalle_pedidos
CREATE TABLE detalle_pedidos (
    id_detalle INT NOT NULL AUTO_INCREMENT,
    id_pedido INT NOT NULL,
    id_producto INT NOT NULL,
    cantidad INT NOT NULL,
    precio_unitario DECIMAL (12,2) NOT NULL,
    CONSTRAINT pk_detalle_pedido PRIMARY KEY (id_detalle),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
     CONSTRAINT ck_detalle_precio CHECK (precio_unitario > 0),
    CONSTRAINT uq_detalle_pedido_producto UNIQUE (id_pedido, id_producto),
    CONSTRAINT fk_detalle_pedidos FOREIGN KEY (id_pedido)
      REFERENCES pedidos (id_pedido)
      ON DELETE CASCADE,
    CONSTRAINT fk_detalle_productos FOREIGN KEY (id_producto)
     REFERENCES productos (id_producto)
      ON DELETE RESTRICT
)ENGINE = InnoDB;
--Tabla usuarios
create table usuarios (
    id_usuario INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NULL,
    nombre_usuario VARCHAR (50) NOT NULL,
    email VARCHAR(100),
    password_hash CHAR (64) NOT NULL,
    --hash es para que la contraseña se guarde y no se pueda ver, para eso se usa el hash 
    salt CHAR (32) NOT NULL,
    --Misma contraseña que no quede igual con el otro usuario, para eso se usa el salt
    rol VARCHAR (20) NOT NULL DEFAULT 'CLIENTE',
   activo BOOLEAN NOT NULL DEFAULT TRUE,
--activo es para que el usuario pueda ingresar a la plataforma, si se desactiva no puede ingresar
    intentos_fallidos INT NOT NULL DEFAULT 0,
    --intentos_fallidos es para que el usuario no pueda ingresar a la plataforma, si se bloquea por intentos fallidos
    bloqueado BOOLEAN NOT NULL DEFAULT FALSE,
    --bloqueado es para que el usuario no pueda ingresar a la plataforma, si se bloquea por intentos fallidos
    ultimo_acceso DATETIME NULL,
    fecha_creacion DATETIME NOT NULL DEFAULT
    CURRENT_TIMESTAMP,
    CONSTRAINT pk_usuarios PRIMARY KEY (id_usuario),
    CONSTRAINT uq_usuarios_nombre UNIQUE(nombre_usuario),
     CONSTRAINT uq_usuarios_email UNIQUE(email),
    CONSTRAINT ck_usuarios_rol CHECK (rol IN ('ADMIN','VENDEDOR','CLIENTE')),
    CONSTRAINT fk_usuarios_clientes FOREIGN KEY (id_cliente)
    REFERENCES clientes(id_cliente)
    ON DELETE SET NULL
    )ENGINE = InnoDB;
    -- Mirar las tablas creadas
    SHOW TABLES;
    --Describir la estructura de la tabla 
    DESCRIBE productos;
    --codigo para ver el script de una tabla creada
    SHOW CREATE TABLE pedidos;

    Diccionario de datos: informacion de las tablas, columnas, indices, etc
    SELECT table_name,constraint_name,constraint_type 
    FROM information_schema.table_constraints 
    WHERE table_schema='tienda_adso'
    ORDER BY table_name,constraint_type;

--Agregar una columna a una tabla existente
ALTER TABLE clientes 
ADD COLUMN fecha_nacimiento DATE NULL AFTER apellidos;

--Cambiar el tipo /tamaño de una columna existente
ALTER TABLE clientes 
MODIFY COLUMN telefono VARCHAR(50) NULL;

--Renombrar una columna CHANGE COLUMN pide nombre viejo y nombre nuevo
-- y la definicion de la columna completa
ALTER TABLE clientes 
CHANGE COLUMN ciudad ciudad_residencia VARCHAR(50) NOT NULL;

--la devolucion de la tabla original
ALTER TABLE clientes 
CHANGE COLUMN ciudad_residencia ciudad VARCHAR(50) NOT NULL;

--Eliminar una columna de una tabla existente
ALTER TABLE clientes
DROP COLUMN fecha_nacimiento;

--Agregar una descripcion a una columna existente
ALTER TABLE productos
ADD CONSTRAINT uq_productos_nombre UNIQUE(nombre);

--Eliminar una restriccion de una tabla existente
ALTER TABLE productos
DROP INDEX uq_productos_nombre;

--Crear indices para busquedas mas rapidas
CREATE INDEX idx_productos_nombre ON productos(nombre);
CREATE INDEX idx_pedidos_fecha ON pedidos(fecha_pedido); 
CREATE INDEX idx_clientes_apellido ON clientes(apellidos,nombres);--Indice compuesto por dos columnas
--Mirar los indices de una tabla 
SHOW INDEX FROM productos;

--Haga el codigo para crear una tabla llamada tabla_practica campos id y detalle
CREATE TABLE tabla_practica (
    id INT AUTO_INCREMENT PRIMARY KEY,
    detalle VARCHAR(255) 
);

--Insertar datos en la tabla_practica
INSERT INTO tabla_practica (detalle) VALUES ('fila 1'),('fila 2');

--Borrar todas las filas de golpe y reinicia el autoincrement
TRUNCATE TABLE tabla_practica;

--Cambiar el nombre de una tabla
RENAME TABLE tabla_practica TO tabla_borrar;

--Eliminar una tabla
DROP TABLE tabla_borrar;
1. Tabla proveedores 

CREATE TABLE proveedores(
id_proveedor INT NOT NULL AUTO_INCREMENT,
nit INT NOT NULL,
razon_social VARCHAR(50)NOT NULL,
telefono VARCHAR(20)NOT NULL,
email VARCHAR(50)NOT NULL,
ciudad BOOLEAN NOT NULL DEFAULT TRUE,
activo BOOLEAN NOT NULL DEFAULT TRUE,
CONSTRAINT pk_proveedores PRIMARY KEY (id_proveedor),
CONSTRAINT uq_proveedores_nit UNIQUE (nit),
CONSTRAINT uq_proveedores_email UNIQUE (email),
CONSTRAINT uq_proveedores_telefono UNIQUE (telefono)
)ENGINE = InnoDB;
2. Tabla alterna para productos y proveedores, para que un producto pueda tener un proveedor y un proveedor pueda tener varios productos.

ALTER TABLE productos
ADD COLUMN id_proveedor INT,
ADD CONSTRAINT fk_productos_proveedores FOREIGN KEY (id_proveedor)
REFERENCES proveedores(id_proveedor)
ON DELETE SET NULL;
3. La tabla direcciones_envio para que un cliente pueda tener varias direcciones de envio y una direccion de envio solo puede pertenecer a un cliente.

CREATE TABLE direcciones_envio(
    id_direccion INT NOT NULL AUTO_INCREMENT,
    id_cliente INT NOT NULL,
    direccion VARCHAR(25)NOT NULL,
    barrio VARCHAR(25)NOT NULL,
    ciudad VARCHAR(25)NOT NULL,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT pk_direcciones_envio PRIMARY KEY (id_direccion),
    CONSTRAINT fk_direcciones_envio_clientes FOREIGN KEY (id_cliente)
    REFERENCES clientes(id_cliente)
    ON DELETE CASCADE
)ENGINE = InnoDB;
4. RESTRICCION DE PRECIO 
ALTER TABLE productos 
ADD CONSTRAINT ck_producto_precio_max CHECK (precio =< 50000000);

5. El indice idx_clientes_ciudad es para que la busqueda de clientes por ciudad sea mas rapida

CREATE INDEX idx_clientes_ciudad ON clientes(ciudad_residencia);

6. La tabla de pruebas es para hacer pruebas de renombrar y eliminar tablas 

CREATE TABLE pruebas(
    id_prueba INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
    nombre_prueba VARCHAR(50)
);
RENAME TABLE pruebas TO pruebas_old;
DROP TABLE pruebas_old;




