/* ==========================================================
   20 EJERCICIOS DE DIFERENTE NIVEL - TRANSact-SQL
   Base de datos: bd_sistema_analisis_comercial_cross_selling
   Incluye 10 basicos/intermedios y 10 avanzados/expertos.
   ========================================================== */

USE bd_sistema_analisis_comercial_cross_selling;
GO

/* ==========================================================
   NIVEL BASICO E INTERMEDIO
   ========================================================== */

/* 1. Listar clientes activos con su segmento. */
SELECT 
    c.id_cliente,
    c.dni,
    c.nombre + ' ' + c.apellido AS cliente,
    c.ingreso_mensual,
    c.distrito,
    s.nombre_segmento
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
WHERE c.estado_cliente = 'Activo'
ORDER BY c.apellido, c.nombre;
GO

/* 2. Mostrar cuentas activas con saldo mayor a 3000. */
SELECT 
    cu.id_cuenta,
    cu.num_cuenta,
    cu.tipo_cuenta,
    cu.moneda,
    cu.saldo_actual,
    c.nombre + ' ' + c.apellido AS cliente
FROM Cuenta cu
INNER JOIN Cliente c ON cu.id_cliente = c.id_cliente
WHERE cu.estado_cuenta = 'Activa'
  AND cu.saldo_actual > 3000
ORDER BY cu.saldo_actual DESC;
GO

/* 3. Contar clientes por segmento. */
SELECT 
    s.nombre_segmento,
    COUNT(c.id_cliente) AS total_clientes
FROM Segmento s
LEFT JOIN Cliente c ON s.id_segmento = c.id_segmento
GROUP BY s.nombre_segmento
ORDER BY total_clientes DESC;
GO

/* 4. Calcular el saldo total por tipo de cuenta y moneda. */
SELECT 
    tipo_cuenta,
    moneda,
    COUNT(*) AS cantidad_cuentas,
    SUM(saldo_actual) AS saldo_total,
    AVG(saldo_actual) AS saldo_promedio
FROM Cuenta
GROUP BY tipo_cuenta, moneda
ORDER BY saldo_total DESC;
GO

/* 5. Listar productos financieros activos ordenados por monto maximo. */
SELECT 
    id_producto,
    nombre_producto,
    tipo_producto,
    tasa_interes,
    comision,
    monto_minimo,
    monto_maximo
FROM Producto_financiero
WHERE estado_producto = 'Activo'
ORDER BY monto_maximo DESC;
GO

/* 6. Clientes que contrataron productos por App o Web. */
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    pf.nombre_producto,
    pc.fecha_contratacion,
    pc.canal_contratacion,
    pc.monto_aprobado,
    pc.monto_utilizado
FROM Producto_cliente pc
INNER JOIN Cliente c ON pc.id_cliente = c.id_cliente
INNER JOIN Producto_financiero pf ON pc.id_producto = pf.id_producto
WHERE pc.canal_contratacion IN ('App', 'Web')
ORDER BY pc.fecha_contratacion DESC;
GO

/* 7. Obtener campañas activas con el producto promocionado. */
SELECT 
    ca.id_campania,
    ca.nombre_campania,
    ca.fecha_inicio,
    ca.fecha_fin,
    ca.canal_principal,
    ca.presupuesto,
    pf.nombre_producto
FROM Campania ca
INNER JOIN Producto_financiero pf ON ca.id_producto = pf.id_producto
WHERE ca.estado_campania = 'Activa'
ORDER BY ca.fecha_inicio;
GO

/* 8. Total de contactos por campaña y respuesta del cliente. */
SELECT 
    ca.nombre_campania,
    cc.respuesta_cliente,
    COUNT(*) AS total_respuestas
FROM Campania_cliente cc
INNER JOIN Campania ca ON cc.id_campania = ca.id_campania
GROUP BY ca.nombre_campania, cc.respuesta_cliente
ORDER BY ca.nombre_campania, total_respuestas DESC;
GO

/* 9. Clientes con nivel de actividad alta en algun periodo. */
SELECT DISTINCT
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    c.ingreso_mensual,
    c.distrito
FROM Comportamiento_cliente co
INNER JOIN Cliente c ON co.id_cliente = c.id_cliente
WHERE co.nivel_actividad = 'Alta'
ORDER BY c.ingreso_mensual DESC;
GO

/* 10. Monto total convertido por canal de conversion. */
SELECT 
    canal_conversion,
    COUNT(*) AS total_conversiones,
    SUM(monto) AS monto_total_convertido,
    AVG(monto) AS ticket_promedio
FROM Conversion
GROUP BY canal_conversion
ORDER BY monto_total_convertido DESC;
GO

/* ==========================================================
   NIVEL AVANZADO Y EXPERTO
   ========================================================== */

/* 11. Ranking de clientes por exposicion total: saldo de productos + saldo en cuentas. */
WITH saldo_cuentas AS (
    SELECT id_cliente, SUM(saldo_actual) AS total_saldo_cuentas
    FROM Cuenta
    GROUP BY id_cliente
),
saldo_productos AS (
    SELECT id_cliente, SUM(saldo_actual) AS total_saldo_productos
    FROM Producto_cliente
    GROUP BY id_cliente
)
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    ISNULL(sc.total_saldo_cuentas, 0) AS total_saldo_cuentas,
    ISNULL(sp.total_saldo_productos, 0) AS total_saldo_productos,
    ISNULL(sc.total_saldo_cuentas, 0) + ISNULL(sp.total_saldo_productos, 0) AS exposicion_total,
    RANK() OVER (ORDER BY ISNULL(sc.total_saldo_cuentas, 0) + ISNULL(sp.total_saldo_productos, 0) DESC) AS ranking_exposicion
FROM Cliente c
LEFT JOIN saldo_cuentas sc ON c.id_cliente = sc.id_cliente
LEFT JOIN saldo_productos sp ON c.id_cliente = sp.id_cliente
ORDER BY ranking_exposicion;
GO

/* 12. Indice de uso de linea por cliente y clasificacion de uso. */
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    SUM(pc.monto_aprobado) AS monto_total_aprobado,
    SUM(pc.monto_utilizado) AS monto_total_utilizado,
    CAST(SUM(pc.monto_utilizado) * 100.0 / NULLIF(SUM(pc.monto_aprobado), 0) AS DECIMAL(10,2)) AS porcentaje_uso,
    CASE 
        WHEN SUM(pc.monto_utilizado) * 1.0 / NULLIF(SUM(pc.monto_aprobado), 0) >= 0.80 THEN 'Uso Critico'
        WHEN SUM(pc.monto_utilizado) * 1.0 / NULLIF(SUM(pc.monto_aprobado), 0) >= 0.50 THEN 'Uso Alto'
        WHEN SUM(pc.monto_utilizado) * 1.0 / NULLIF(SUM(pc.monto_aprobado), 0) >= 0.25 THEN 'Uso Medio'
        ELSE 'Uso Bajo'
    END AS clasificacion_uso
FROM Cliente c
INNER JOIN Producto_cliente pc ON c.id_cliente = pc.id_cliente
GROUP BY c.id_cliente, c.nombre, c.apellido
ORDER BY porcentaje_uso DESC;
GO

/* 13. Tasa de conversion por campaña. */
SELECT 
    ca.id_campania,
    ca.nombre_campania,
    COUNT(cc.id_camp_cliente) AS clientes_contactados,
    COUNT(cv.id_conversion) AS conversiones,
    CAST(COUNT(cv.id_conversion) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_conversion_porcentaje,
    SUM(ISNULL(cv.monto, 0)) AS monto_convertido
FROM Campania ca
LEFT JOIN Campania_cliente cc ON ca.id_campania = cc.id_campania
LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
GROUP BY ca.id_campania, ca.nombre_campania
ORDER BY tasa_conversion_porcentaje DESC;
GO

/* 14. ROI comercial aproximado por campaña: monto convertido / presupuesto. */
SELECT 
    ca.nombre_campania,
    ca.presupuesto,
    SUM(ISNULL(cv.monto, 0)) AS monto_convertido,
    CAST((SUM(ISNULL(cv.monto, 0)) - ca.presupuesto) AS DECIMAL(18,2)) AS utilidad_bruta_aprox,
    CAST(SUM(ISNULL(cv.monto, 0)) * 100.0 / NULLIF(ca.presupuesto, 0) AS DECIMAL(10,2)) AS roi_porcentaje
FROM Campania ca
LEFT JOIN Campania_cliente cc ON ca.id_campania = cc.id_campania
LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
GROUP BY ca.nombre_campania, ca.presupuesto
ORDER BY roi_porcentaje DESC;
GO

/* 15. Detectar clientes con potencial de cross selling: alta actividad, pocos productos y saldo promedio alto. */
WITH resumen_productos AS (
    SELECT id_cliente, COUNT(*) AS cantidad_productos
    FROM Producto_cliente
    GROUP BY id_cliente
),
resumen_comportamiento AS (
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
    ISNULL(rp.cantidad_productos, 0) AS cantidad_productos,
    rc.promedio_transacciones,
    rc.saldo_promedio_general,
    CASE 
        WHEN rc.promedio_transacciones >= 20 AND ISNULL(rp.cantidad_productos, 0) <= 2 AND rc.saldo_promedio_general >= 2500 THEN 'Alto potencial'
        WHEN rc.promedio_transacciones >= 12 AND ISNULL(rp.cantidad_productos, 0) <= 3 THEN 'Potencial medio'
        ELSE 'Bajo potencial'
    END AS potencial_cross_selling
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
LEFT JOIN resumen_productos rp ON c.id_cliente = rp.id_cliente
LEFT JOIN resumen_comportamiento rc ON c.id_cliente = rc.id_cliente
ORDER BY potencial_cross_selling, rc.saldo_promedio_general DESC;
GO

/* 16. Analisis RFM simplificado comercial: recencia, frecuencia y monetizacion de conversiones. */
WITH conversion_cliente AS (
    SELECT 
        cc.id_cliente,
        MAX(cv.fecha_conversion) AS ultima_conversion,
        COUNT(cv.id_conversion) AS frecuencia_conversion,
        SUM(cv.monto) AS monto_total_conversion
    FROM Campania_cliente cc
    INNER JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
    GROUP BY cc.id_cliente
)
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    ultima_conversion,
    DATEDIFF(DAY, ultima_conversion, '2024-06-01') AS dias_desde_ultima_conversion,
    frecuencia_conversion,
    monto_total_conversion,
    NTILE(3) OVER (ORDER BY DATEDIFF(DAY, ultima_conversion, '2024-06-01') ASC) AS score_recencia,
    NTILE(3) OVER (ORDER BY frecuencia_conversion DESC) AS score_frecuencia,
    NTILE(3) OVER (ORDER BY monto_total_conversion DESC) AS score_monetario
FROM Cliente c
INNER JOIN conversion_cliente vc ON c.id_cliente = vc.id_cliente
ORDER BY monto_total_conversion DESC;
GO

/* 17. Producto recomendado por segmento segun mayor tasa de conversion historica. */
WITH conversion_segmento_producto AS (
    SELECT 
        s.id_segmento,
        s.nombre_segmento,
        pf.id_producto,
        pf.nombre_producto,
        COUNT(cc.id_camp_cliente) AS total_contactos,
        COUNT(cv.id_conversion) AS total_conversiones,
        CAST(COUNT(cv.id_conversion) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_conversion
    FROM Segmento s
    INNER JOIN Cliente c ON s.id_segmento = c.id_segmento
    INNER JOIN Campania_cliente cc ON c.id_cliente = cc.id_cliente
    INNER JOIN Campania ca ON cc.id_campania = ca.id_campania
    INNER JOIN Producto_financiero pf ON ca.id_producto = pf.id_producto
    LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
    GROUP BY s.id_segmento, s.nombre_segmento, pf.id_producto, pf.nombre_producto
),
ranked AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY id_segmento ORDER BY tasa_conversion DESC, total_conversiones DESC) AS rn
    FROM conversion_segmento_producto
)
SELECT 
    nombre_segmento,
    nombre_producto AS producto_recomendado,
    total_contactos,
    total_conversiones,
    tasa_conversion
FROM ranked
WHERE rn = 1
ORDER BY tasa_conversion DESC;
GO

/* 18. Comparar ingreso mensual contra promedio del segmento. */
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    s.nombre_segmento,
    c.ingreso_mensual,
    AVG(c.ingreso_mensual) OVER (PARTITION BY c.id_segmento) AS ingreso_promedio_segmento,
    c.ingreso_mensual - AVG(c.ingreso_mensual) OVER (PARTITION BY c.id_segmento) AS diferencia_vs_segmento,
    CASE 
        WHEN c.ingreso_mensual > AVG(c.ingreso_mensual) OVER (PARTITION BY c.id_segmento) THEN 'Sobre promedio'
        WHEN c.ingreso_mensual < AVG(c.ingreso_mensual) OVER (PARTITION BY c.id_segmento) THEN 'Bajo promedio'
        ELSE 'En promedio'
    END AS comparacion
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
ORDER BY s.nombre_segmento, diferencia_vs_segmento DESC;
GO

/* 19. Embudo comercial por campaña: enviados, contactados, aceptados y convertidos. */
SELECT 
    ca.nombre_campania,
    COUNT(cc.id_camp_cliente) AS enviados,
    SUM(CASE WHEN cc.estado_contacto = 'Contactado' THEN 1 ELSE 0 END) AS contactados,
    SUM(CASE WHEN cc.respuesta_cliente = 'Acepta' THEN 1 ELSE 0 END) AS aceptados,
    COUNT(cv.id_conversion) AS convertidos,
    CAST(SUM(CASE WHEN cc.estado_contacto = 'Contactado' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_contactabilidad,
    CAST(SUM(CASE WHEN cc.respuesta_cliente = 'Acepta' THEN 1 ELSE 0 END) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_aceptacion,
    CAST(COUNT(cv.id_conversion) * 100.0 / NULLIF(COUNT(cc.id_camp_cliente), 0) AS DECIMAL(10,2)) AS tasa_conversion
FROM Campania ca
LEFT JOIN Campania_cliente cc ON ca.id_campania = cc.id_campania
LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
GROUP BY ca.nombre_campania
ORDER BY tasa_conversion DESC;
GO

/* 20. Score comercial experto para priorizar clientes en una nueva campaña. */
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
    SELECT cc.id_cliente, COUNT(cv.id_conversion) AS cant_conversiones, SUM(ISNULL(cv.monto,0)) AS monto_conversion
    FROM Campania_cliente cc
    LEFT JOIN Conversion cv ON cc.id_camp_cliente = cv.id_camp_cliente
    GROUP BY cc.id_cliente
)
SELECT 
    c.id_cliente,
    c.nombre + ' ' + c.apellido AS cliente,
    s.nombre_segmento,
    c.ingreso_mensual,
    ISNULL(p.cant_productos, 0) AS cant_productos,
    ISNULL(p.linea_disponible, 0) AS linea_disponible,
    ISNULL(a.prom_transacciones, 0) AS prom_transacciones,
    ISNULL(a.prom_saldo, 0) AS prom_saldo,
    ISNULL(cv.cant_conversiones, 0) AS cant_conversiones,
    (
        CASE WHEN c.ingreso_mensual >= 5000 THEN 30 WHEN c.ingreso_mensual >= 3000 THEN 20 ELSE 10 END +
        CASE WHEN ISNULL(a.prom_transacciones, 0) >= 25 THEN 25 WHEN ISNULL(a.prom_transacciones, 0) >= 15 THEN 15 ELSE 5 END +
        CASE WHEN ISNULL(p.linea_disponible, 0) >= 20000 THEN 20 WHEN ISNULL(p.linea_disponible, 0) >= 8000 THEN 10 ELSE 5 END +
        CASE WHEN ISNULL(cv.cant_conversiones, 0) >= 2 THEN 25 WHEN ISNULL(cv.cant_conversiones, 0) = 1 THEN 15 ELSE 0 END
    ) AS score_comercial,
    CASE 
        WHEN (
            CASE WHEN c.ingreso_mensual >= 5000 THEN 30 WHEN c.ingreso_mensual >= 3000 THEN 20 ELSE 10 END +
            CASE WHEN ISNULL(a.prom_transacciones, 0) >= 25 THEN 25 WHEN ISNULL(a.prom_transacciones, 0) >= 15 THEN 15 ELSE 5 END +
            CASE WHEN ISNULL(p.linea_disponible, 0) >= 20000 THEN 20 WHEN ISNULL(p.linea_disponible, 0) >= 8000 THEN 10 ELSE 5 END +
            CASE WHEN ISNULL(cv.cant_conversiones, 0) >= 2 THEN 25 WHEN ISNULL(cv.cant_conversiones, 0) = 1 THEN 15 ELSE 0 END
        ) >= 80 THEN 'Prioridad Alta'
        WHEN (
            CASE WHEN c.ingreso_mensual >= 5000 THEN 30 WHEN c.ingreso_mensual >= 3000 THEN 20 ELSE 10 END +
            CASE WHEN ISNULL(a.prom_transacciones, 0) >= 25 THEN 25 WHEN ISNULL(a.prom_transacciones, 0) >= 15 THEN 15 ELSE 5 END +
            CASE WHEN ISNULL(p.linea_disponible, 0) >= 20000 THEN 20 WHEN ISNULL(p.linea_disponible, 0) >= 8000 THEN 10 ELSE 5 END +
            CASE WHEN ISNULL(cv.cant_conversiones, 0) >= 2 THEN 25 WHEN ISNULL(cv.cant_conversiones, 0) = 1 THEN 15 ELSE 0 END
        ) >= 55 THEN 'Prioridad Media'
        ELSE 'Prioridad Baja'
    END AS prioridad_campania
FROM Cliente c
INNER JOIN Segmento s ON c.id_segmento = s.id_segmento
LEFT JOIN productos p ON c.id_cliente = p.id_cliente
LEFT JOIN actividad a ON c.id_cliente = a.id_cliente
LEFT JOIN conversiones cv ON c.id_cliente = cv.id_cliente
ORDER BY score_comercial DESC;
GO
