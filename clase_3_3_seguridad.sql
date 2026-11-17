
/* CLASE 3: SEGURIDAD EN BASE DE DATOS

OBJETIVO:
Evidenciar que las contraseñas estén protegidas
mediante HASH y SALT y aplicar prácticas de
seguridad sobre los datos.

1. HASH VS CIFRADO
2. CONTRASEÑAS CON HASH + SALT (SHA2)
3. PROCEDIMIENTOS PARA REGISTRAR USUARIOS,
   HACER LOGIN Y CAMBIAR CLAVE
4. CIFRADO REVERSIBLE (AES)
5. AUDITORÍAS CON TRIGGER
6. VISTAS QUE OCULTAN DATOS SENSIBLES
7. USUARIOS Y ROLES (GRANT / REVOKE)
8. PREVENCIÓN DE SQL INJECTION
*/


/* ==========================================
   1. HASH VS CIFRADO
   ==========================================

   HASH:
   - Convierte un texto en una huella de longitud fija.
   - No se puede revertir.
   - Para validar el login se calcula nuevamente
     el HASH y se compara con el guardado.
   - SALT: texto aleatorio distinto para cada usuario.

   CIFRADO:
   - Es reversible.
   - Se utiliza para datos sensibles que necesitamos leer.
   - Con una llave se cifra y con la misma llave se descifra.

   Nunca se deben guardar contraseñas en texto plano.
*/


-- Demostración: el mismo texto siempre da el mismo HASH.

SELECT SHA2('clave123*', 256) AS hash_1;

SELECT SHA2('clave123*', 256) AS hash_2;


-- Demostración utilizando SALT.

SELECT SHA2(CONCAT('a1b2c3', 'clave123*'), 256)
AS hash_usuario_A;

SELECT SHA2(CONCAT('a9y8x7', 'clave123*'), 256)
AS hash_usuario_B;


-- Generar un SALT aleatorio de 32 caracteres hexadecimales.
-- Se mezclan UUID, RAND y la hora con milisegundos.

SELECT LEFT(
    SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256),
    32
) AS salt_aleatorio;


/* Lo que nunca se debe hacer con contraseñas.
   Si alguien roba la base de datos podría ver las claves.

   INSERT INTO usuarios (...)
   VALUES (..., 'MiClave123', ...); -- MAL
*/


/* ==========================================
   3. PROCEDIMIENTOS ALMACENADOS
   ==========================================

   Centralizamos la lógica de seguridad.
   La aplicación utiliza los procedimientos
   para registrar usuarios, iniciar sesión
   y cambiar contraseñas.

   DELIMITER cambia el final de la sentencia
   para poder utilizar ; dentro del procedimiento.
*/


-- Eliminar procedimientos anteriores.

DROP PROCEDURE IF EXISTS sp_registrar_usuario;
DROP PROCEDURE IF EXISTS sp_registrar_usuarioV2;
DROP PROCEDURE IF EXISTS sp_login_usuario;
DROP PROCEDURE IF EXISTS sp_login;
DROP PROCEDURE IF EXISTS sp_cambiar_password;


DELIMITER //


/* ==========================================
   3.1 REGISTRAR USUARIO
   ========================================== */

CREATE PROCEDURE sp_registrar_usuario(
    IN p_nombre_usuario VARCHAR(50),
    IN p_email VARCHAR(100),
    IN p_password VARCHAR(100),
    IN p_rol VARCHAR(20),
    IN p_id_cliente INT
)
BEGIN

    DECLARE v_salt CHAR(32);

    -- Política de contraseñas:
    -- Mínimo 8 caracteres, una mayúscula y un número.

    IF CHAR_LENGTH(p_password) < 8
       OR CAST(p_password AS BINARY) =
          CAST(LOWER(p_password) AS BINARY)
       OR p_password NOT REGEXP '[0-9]' THEN

        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT =
        'La contraseña debe tener minimo 8 caracteres, una mayuscula y un numero';

    END IF;


    -- Generar SALT aleatorio.

    SET v_salt = LEFT(
        SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256),
        32
    );


    -- Insertar usuario guardando HASH y SALT.

    INSERT INTO usuarios (
        id_cliente,
        nombre_usuario,
        email,
        password_hash,
        salt,
        rol
    )
    VALUES (
        p_id_cliente,
        p_nombre_usuario,
        p_email,
        SHA2(CONCAT(v_salt, p_password), 256),
        v_salt,
        p_rol
    );

END //


/* ==========================================
   3.2 INICIAR SESIÓN
   ========================================== */

CREATE PROCEDURE sp_login(
    IN p_nombre_usuario VARCHAR(50),
    IN p_password VARCHAR(100),
    OUT p_resultado VARCHAR(100)
)
BEGIN

    DECLARE v_id INT DEFAULT NULL;
    DECLARE v_hash CHAR(64);
    DECLARE v_salt CHAR(32);
    DECLARE v_bloqueado BOOLEAN DEFAULT FALSE;
    DECLARE v_intentos INT DEFAULT 0;

    DECLARE CONTINUE HANDLER FOR NOT FOUND
        SET v_id = NULL;


    SELECT
        id_usuario,
        password_hash,
        salt,
        bloqueado,
        intentos_fallidos
    INTO
        v_id,
        v_hash,
        v_salt,
        v_bloqueado,
        v_intentos
    FROM usuarios
    WHERE nombre_usuario = p_nombre_usuario
      AND activo = TRUE;


    IF v_id IS NULL THEN

        SET p_resultado =
        'Usuario o contraseña incorrectos';


    ELSEIF v_bloqueado THEN

        SET p_resultado =
        'Usuario bloqueado. Contacte al administrador';


    ELSEIF v_hash =
           SHA2(CONCAT(v_salt, p_password), 256) THEN

        UPDATE usuarios
        SET intentos_fallidos = 0,
            ultimo_acceso = NOW()
        WHERE id_usuario = v_id;

        SET p_resultado = 'Acceso concedido';


    ELSE

        UPDATE usuarios
        SET intentos_fallidos =
            COALESCE(v_intentos, 0) + 1,

            bloqueado =
            (COALESCE(v_intentos, 0) + 1 >= 3)

        WHERE id_usuario = v_id;

        SET p_resultado =
        'Usuario o contraseña incorrectos';

    END IF;

END //


/* ==========================================
   3.3 CAMBIAR CONTRASEÑA
   ========================================== */

CREATE PROCEDURE sp_cambiar_password(
    IN p_nombre_usuario VARCHAR(50),
    IN p_password_actual VARCHAR(100),
    IN p_password_nueva VARCHAR(100),
    OUT p_resultado VARCHAR(100)
)
BEGIN

    DECLARE v_salt_nuevo CHAR(32);


    -- Verificar contraseña actual.

    IF NOT EXISTS (
        SELECT 1
        FROM usuarios
        WHERE nombre_usuario = p_nombre_usuario
        AND password_hash =
            SHA2(CONCAT(salt, p_password_actual), 256)
    ) THEN

        SET p_resultado =
        'La contraseña actual no es correcta';


    -- Validar nueva contraseña.

    ELSEIF CHAR_LENGTH(p_password_nueva) < 8
       OR CAST(p_password_nueva AS BINARY) =
          CAST(LOWER(p_password_nueva) AS BINARY)
       OR p_password_nueva NOT REGEXP '[0-9]' THEN

        SET p_resultado =
        'La nueva contraseña no cumple con la politica';


    ELSE

        -- Generar nuevo SALT.

        SET v_salt_nuevo = LEFT(
            SHA2(CONCAT(UUID(), RAND(), NOW(6)), 256),
            32
        );


        -- Actualizar HASH y SALT.

        UPDATE usuarios
        SET salt = v_salt_nuevo,
            password_hash =
            SHA2(CONCAT(v_salt_nuevo, p_password_nueva), 256)
        WHERE nombre_usuario = p_nombre_usuario;


        SET p_resultado =
        'Contraseña cambiada correctamente';

    END IF;

END //

DELIMITER ;


/* ==========================================
   5. AUDITORÍA CON TRIGGER
   ==========================================

   El trigger registra eventos de seguridad
   cuando se actualiza la tabla usuarios.

   Guarda quién y cuándo realizó el cambio
   de contraseña o el bloqueo del usuario.

   Nunca guarda la contraseña en la auditoría.
*/


-- Crear tabla de auditoría.

CREATE TABLE IF NOT EXISTS auditoria_usuarios (
    id_auditoria INT AUTO_INCREMENT PRIMARY KEY,
    id_usuario INT NOT NULL,
    accion VARCHAR(30) NOT NULL,
    detalle VARCHAR(255) NULL,
    usuario_bd VARCHAR(100) NOT NULL,
    fecha DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP
) ENGINE = InnoDB;


-- Eliminar trigger anterior.

DROP TRIGGER IF EXISTS trg_usuario_auditoria;
DROP TRIGGER IF EXISTS trg_usuarios_auditoria;


DELIMITER //


-- Crear trigger de auditoría.

CREATE TRIGGER trg_usuarios_auditoria
AFTER UPDATE ON usuarios
FOR EACH ROW
BEGIN

    -- OLD = valores antes del UPDATE.
    -- NEW = valores después del UPDATE.


    -- Registrar cambio de contraseña.

    IF NOT (NEW.password_hash <=> OLD.password_hash) THEN

        INSERT INTO auditoria_usuarios (
            id_usuario,
            accion,
            detalle,
            usuario_bd
        )
        VALUES (
            NEW.id_usuario,
            'CAMBIO_PASSWORD',
            'Se cambio la contraseña',
            CURRENT_USER()
        );

    END IF;


    -- Registrar bloqueo de usuario.

    IF NEW.bloqueado = TRUE
       AND OLD.bloqueado = FALSE THEN

        INSERT INTO auditoria_usuarios (
            id_usuario,
            accion,
            detalle,
            usuario_bd
        )
        VALUES (
            NEW.id_usuario,
            'BLOQUEO',
            'Bloqueado por 3 intentos fallidos',
            CURRENT_USER()
        );

    END IF;

END //

DELIMITER ;


/* ==========================================
   PRUEBAS DE REGISTRO, LOGIN Y BLOQUEO
   ========================================== */


-- Registrar usuarios.

CALL sp_registrar_usuario(
    'admin',
    'admin@tienda.com',
    'Admin*2026Seguro',
    'ADMIN',
    NULL
);

CALL sp_registrar_usuario(
    'vendedor',
    'ventas@tienda.com',
    'Ventas#2026',
    'VENDEDOR',
    NULL
);

CALL sp_registrar_usuario(
    'ana.gomez',
    'ana.gomez@tienda.com',
    'AnaGomez2026',
    'CLIENTE',
    1
);

CALL sp_registrar_usuario(
    'carlos.perez',
    'carlos.perez@tienda.com',
    'Carlos2026!',
    'CLIENTE',
    2
);


-- Este registro debe rechazarse por contraseña débil.

CALL sp_registrar_usuario(
    'debil',
    'debil@tienda.com',
    '12345',
    'CLIENTE',
    NULL
);


-- Consultar HASH y SALT.

SELECT
    id_usuario,
    nombre_usuario,
    rol,
    salt,
    password_hash
FROM usuarios;


-- Probar login correcto.

CALL sp_login(
    'ana.gomez',
    'AnaGomez2026',
    @resultado
);

SELECT @resultado AS login_correcto;


-- Tres intentos fallidos para bloquear al usuario.

CALL sp_login('carlos.perez', 'clave_mala', @r1);

CALL sp_login('carlos.perez', 'clave_mala', @r2);

CALL sp_login('carlos.perez', 'clave_mala', @r3);

CALL sp_login('carlos.perez', 'Carlos2026!', @r4);


-- Consultar resultados de los cuatro intentos.

SELECT @r1, @r2, @r3, @r4;


-- Consultar intentos fallidos y bloqueos.

SELECT
    nombre_usuario,
    intentos_fallidos,
    bloqueado
FROM usuarios;


-- Cambiar contraseña.

CALL sp_cambiar_password(
    'ana.gomez',
    'AnaGomez2026',
    'NuevaClave2026',
    @r
);

SELECT @r AS cambio;


-- Consultar auditoría.

SELECT * FROM auditoria_usuarios;


-- El administrador desbloquea al usuario.

UPDATE usuarios
SET bloqueado = FALSE,
    intentos_fallidos = 0
WHERE nombre_usuario = 'carlos.perez';
