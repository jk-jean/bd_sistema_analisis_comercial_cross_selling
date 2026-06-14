/* ==========================================================
   10 EJERCICIOS DE VISTAS, PROCEDIMIENTOS ALMACENADOS Y FUNCIONES
   Base de datos: bd_sistema_analisis_comercial_cross_selling
   Contiene: 3 vistas, 4 procedimientos almacenados y 3 funciones.
   ========================================================== */

USE bd_sistema_analisis_comercial_cross_selling;
GO

/* ==========================================================
   VISTAS
   ========================================================== */

/* 1. Vista: resumen integral de clientes para analisis comercial. */
CREATE OR ALTER VIEW vw_resumen_cliente_cross_selling AS
SELECT 
    c.id_cliente,
    c.dni,
    c.nombre + ' ' + c.apellido AS cliente,
    c.ingreso_mensual,
    c.situacion_laboral,
    c.distrito,
    c.estado_cliente,
    s.nombre_segmento,
    COUNT(DISTINCT cu.id_cuenta) AS cantidad_cuentas,
    ISNULL(SUM(DISTINCT cu.saldo_actual), 0) AS saldo_total_cuentas,
    COUNT(DISTINCT pc.id_producto_cliente) AS cantidad_productos,
    ISNULL(SUM(pc.saldo_actual), 0) AS saldo_total_productos
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
LEFT JOIN Cuenta cu ON c.id_cliente = cu.id_cliente
LEFT JOIN Producto_cliente pc ON c.id_cliente = pc.id_cliente
GROUP BY 
    c.id_cliente, c.dni, c.nombre, c.apellido, c.ingreso_mensual,
    c.situacion_laboral, c.distrito, c.estado_cliente, s.nombre_segmento;
GO

/* Prueba */
SELECT * FROM vw_resumen_cliente_cross_selling ORDER BY saldo_total_productos DESC;
GO

/* 2. Vista: rendimiento de campañas y conversiones. */
CREATE OR ALTER VIEW vw_rendimiento_campanias AS
SELECT 
    ca.id_campania,
    ca.nombre_campania,
    ca.canal_principal,
    ca.presupuesto,
    pf.nombre_producto,
    COUNT(cc.id_camp_cliente) AS total_enviados,
    SUM(CASE WHEN cc.estado_contacto = 'Contactado' THEN 1 ELSE 0 END) AS total_contactados,
    SUM(CASE WHEN cc.respuesta_cliente = 'Acepta' THEN 1 ELSE 0 END) AS total_aceptados,
    COUNT(cv.id_conversion) AS total_conversiones,
    ISNULL(SUM(cv.monto), 0) AS monto_total_convertido,
    CAST(COUNT(cv.id_conversion) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_conversion
FROM Campania ca
INNER JOIN Producto_financiero pf ON ca.id_producto = pf.id_producto
LEFT JOIN Campania_cliente cc ON ca.id_campania = cc.id_campania
LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
GROUP BY ca.id_campania, ca.nombre_campania, ca.canal_principal, ca.presupuesto, pf.nombre_producto;
GO

/* Prueba */
SELECT * FROM vw_rendimiento_campanias ORDER BY tasa_conversion DESC;
GO

/* 3. Vista: clientes con alto potencial de cross selling. */
CREATE OR ALTER VIEW vw_clientes_potencial_cross_selling AS
WITH resumen_productos AS (
    SELECT id_cliente, COUNT(*) AS cantidad_productos
    FROM Producto_cliente
    GROUP BY id_cliente
),
resumen_actividad AS (
    SELECT 
        id_cliente,
        AVG(CAST(cantidad_transaccion AS DECIMAL(10,2))) AS promedio_transacciones,
        AVG(saldo_promedio) AS saldo_promedio_general
    FROM Comportamiento_cliente
    GROUP BY id_cliente
)
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    s.nombre_segmento,
    c.ingreso_mensual,
    ISNULL(rp.cantidad_productos, 0) AS cantidad_productos,
    ISNULL(ra.promedio_transacciones, 0) AS promedio_transacciones,
    ISNULL(ra.saldo_promedio_general, 0) AS saldo_promedio_general,
    CASE 
        WHEN ISNULL(ra.promedio_transacciones, 0) >= 20 AND ISNULL(rp.cantidad_productos, 0) <= 2 THEN 'Alto'
        WHEN ISNULL(ra.promedio_transacciones, 0) >= 12 THEN 'Medio'
        ELSE 'Bajo'
    END AS nivel_potencial
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
LEFT JOIN resumen_productos rp ON c.id_cliente = rp.id_cliente
LEFT JOIN resumen_actividad ra ON c.id_cliente = ra.id_cliente;
GO

/* Prueba */
SELECT * FROM vw_clientes_potencial_cross_selling WHERE nivel_potencial IN ('Alto', 'Medio');
GO

/* ==========================================================
   PROCEDIMIENTOS ALMACENADOS
   ========================================================== */

/* 4. Procedimiento: buscar clientes por segmento. */
CREATE OR ALTER PROCEDURE sp_buscar_clientes_por_segmento
    @nombre_segmento VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        c.id_cliente,
        c.dni,
        c.nombre + ' ' + c.apellido AS cliente,
        c.ingreso_mensual,
        c.distrito,
        s.nombre_segmento
    FROM Cliente c
    INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
    WHERE s.nombre_segmento LIKE '%' + @nombre_segmento + '%'
    ORDER BY c.ingreso_mensual DESC;
END;
GO

/* Prueba */
EXEC sp_buscar_clientes_por_segmento @nombre_segmento = 'Premium';
GO

/* 5. Procedimiento: obtener dashboard de una campaña. */
CREATE OR ALTER PROCEDURE sp_dashboard_campania
    @id_campania INT
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ca.id_campania,
        ca.nombre_campania,
        ca.fecha_inicio,
        ca.fecha_fin,
        ca.canal_principal,
        ca.presupuesto,
        pf.nombre_producto,
        COUNT(cc.id_camp_cliente) AS enviados,
        SUM(CASE WHEN cc.estado_contacto = 'Contactado' THEN 1 ELSE 0 END) AS contactados,
        SUM(CASE WHEN cc.respuesta_cliente = 'Acepta' THEN 1 ELSE 0 END) AS aceptados,
        COUNT(cv.id_conversion) AS conversiones,
        ISNULL(SUM(cv.monto), 0) AS monto_convertido,
        CAST(COUNT(cv.id_conversion) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_conversion,
        CAST(ISNULL(SUM(cv.monto), 0) * 100.0 / NULLIF(ca.presupuesto, 0) AS DECIMAL(10,2)) AS roi_porcentaje
    FROM Campania ca
    INNER JOIN Producto_financiero pf ON ca.id_producto = pf.id_producto
    LEFT JOIN Campania_cliente cc ON ca.id_campania = cc.id_campania
    LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
    WHERE ca.id_campania = @id_campania
    GROUP BY ca.id_campania, ca.nombre_campania, ca.fecha_inicio, ca.fecha_fin, ca.canal_principal, ca.presupuesto, pf.nombre_producto;
END;
GO

/* Prueba */
EXEC sp_dashboard_campania @id_campania = 1001;
GO

/* 6. Procedimiento: registrar contacto de campaña con validacion de duplicado. */
CREATE OR ALTER PROCEDURE sp_registrar_contacto_campania
    @id_campania INT,
    @id_cliente INT,
    @fecha_envio DATE,
    @canal VARCHAR(20),
    @estado_contacto VARCHAR(15),
    @respuesta_cliente VARCHAR(20),
    @fecha_respuesta DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 
        FROM Campania_cliente 
        WHERE id_campania = @id_campania AND id_cliente = @id_cliente
    )
    BEGIN
        RAISERROR('El cliente ya fue registrado en esta campania.', 16, 1);
        RETURN;
    END;

    INSERT INTO Campania_cliente
    (fecha_envio, canal, estado_contacto, respuesta_cliente, fecha_respuesta, id_campania, id_cliente)
    VALUES
    (@fecha_envio, @canal, @estado_contacto, @respuesta_cliente, @fecha_respuesta, @id_campania, @id_cliente);

    SELECT SCOPE_IDENTITY() AS nuevo_id_camp_cliente;
END;
GO

/* Prueba sugerida, usar con un cliente que no exista en esa campaña:
EXEC sp_registrar_contacto_campania 
    @id_campania = 1004,
    @id_cliente = 1001,
    @fecha_envio = '2024-05-20',
    @canal = 'Ejecutivo',
    @estado_contacto = 'Contactado',
    @respuesta_cliente = 'Acepta',
    @fecha_respuesta = '2024-05-21';
*/
GO

/* 7. Procedimiento: ranking de clientes prioritarios segun score comercial. */
CREATE OR ALTER PROCEDURE sp_ranking_clientes_prioritarios
    @top INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    WITH productos AS (
        SELECT id_cliente, COUNT(*) AS cant_productos, SUM(monto_aprobado - monto_utilizado) AS linea_disponible
        FROM Producto_cliente
        GROUP BY id_cliente
    ),
    actividad AS (
        SELECT id_cliente, AVG(CAST(cantidad_transaccion AS DECIMAL(10,2))) AS prom_transacciones, AVG(saldo_promedio) AS prom_saldo
        FROM Comportamiento_cliente
        GROUP BY id_cliente
    ),
    conversiones AS (
        SELECT cc.id_cliente, COUNT(cv.id_conversion) AS cant_conversiones
        FROM Campania_cliente cc
        LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
        GROUP BY cc.id_cliente
    )
    SELECT TOP (@top)
        c.id_cliente,
        c.nombre + ' ' + c.apellido AS cliente,
        s.nombre_segmento,
        c.ingreso_mensual,
        ISNULL(a.prom_transacciones, 0) AS prom_transacciones,
        ISNULL(p.linea_disponible, 0) AS linea_disponible,
        ISNULL(cv.cant_conversiones, 0) AS cant_conversiones,
        (
            CASE WHEN c.ingreso_mensual >= 5000 THEN 30 WHEN c.ingreso_mensual >= 3000 THEN 20 ELSE 10 END +
            CASE WHEN ISNULL(a.prom_transacciones, 0) >= 25 THEN 25 WHEN ISNULL(a.prom_transacciones, 0) >= 15 THEN 15 ELSE 5 END +
            CASE WHEN ISNULL(p.linea_disponible, 0) >= 20000 THEN 20 WHEN ISNULL(p.linea_disponible, 0) >= 8000 THEN 10 ELSE 5 END +
            CASE WHEN ISNULL(cv.cant_conversiones, 0) >= 2 THEN 25 WHEN ISNULL(cv.cant_conversiones, 0) = 1 THEN 15 ELSE 0 END
        ) AS score_comercial
    FROM Cliente c
    INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
    LEFT JOIN productos p ON c.id_cliente = p.id_cliente
    LEFT JOIN actividad a ON c.id_cliente = a.id_cliente
    LEFT JOIN conversiones cv ON c.id_cliente = cv.id_cliente
    ORDER BY score_comercial DESC;
END;
GO

/* Prueba */
EXEC sp_ranking_clientes_prioritarios @top = 10;
GO

/* ==========================================================
   FUNCIONES
   ========================================================== */

/* 8. Funcion escalar: calcular edad de un cliente. */
CREATE OR ALTER FUNCTION fn_edad_cliente (@fecha_nacimiento DATE)
RETURNS INT
AS
BEGIN
    DECLARE @edad INT;

    SET @edad = DATEDIFF(YEAR, @fecha_nacimiento, GETDATE())
              - CASE 
                    WHEN DATEADD(YEAR, DATEDIFF(YEAR, @fecha_nacimiento, GETDATE()), @fecha_nacimiento) > GETDATE() 
                    THEN 1 ELSE 0 
                END;

    RETURN @edad;
END;
GO

/* Prueba */
SELECT id_cliente, nombre + ' ' + apellido AS cliente, dbo.fn_edad_cliente(fecha_nacimiento) AS edad
FROM Cliente;
GO

/* 9. Funcion escalar: calcular porcentaje de uso de producto contratado. */
CREATE OR ALTER FUNCTION fn_porcentaje_uso_producto
(
    @monto_aprobado DECIMAL(18,2),
    @monto_utilizado DECIMAL(18,2)
)
RETURNS DECIMAL(10,2)
AS
BEGIN
    DECLARE @porcentaje DECIMAL(10,2);

    SET @porcentaje = CASE 
                        WHEN @monto_aprobado IS NULL OR @monto_aprobado = 0 THEN 0
                        ELSE (@monto_utilizado * 100.0 / @monto_aprobado)
                      END;

    RETURN @porcentaje;
END;
GO

/* Prueba */
SELECT 
    id_producto_cliente,
    monto_aprobado,
    monto_utilizado,
    dbo.fn_porcentaje_uso_producto(monto_aprobado, monto_utilizado) AS porcentaje_uso
FROM Producto_cliente
ORDER BY porcentaje_uso DESC;
GO

/* 10. Funcion de tabla: historial comercial de un cliente. */
CREATE OR ALTER FUNCTION fn_historial_comercial_cliente (@id_cliente INT)
RETURNS TABLE
AS
RETURN
(
    SELECT 
        c.id_cliente,
        c.nombre + ' ' + c.apellido AS cliente,
        ca.nombre_campania,
        pf.nombre_producto,
        cc.fecha_envio,
        cc.estado_contacto,
        cc.respuesta_cliente,
        cv.fecha_conversion,
        cv.monto AS monto_conversion,
        cv.estado_conversion
    FROM Cliente c
    INNER JOIN Campania_cliente cc ON c.id_cliente = cc.id_cliente
    INNER JOIN Campania ca ON cc.id_campania = ca.id_campania
    INNER JOIN Producto_financiero pf ON ca.id_producto = pf.id_producto
    LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
    WHERE c.id_cliente = @id_cliente
);
GO

/* Prueba */
SELECT * FROM dbo.fn_historial_comercial_cliente(1001)
ORDER BY fecha_envio;
GO
