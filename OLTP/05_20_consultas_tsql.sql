USE pdan_bd_sistema_riesgo_crediticio;
GO


-- 1. Listar clientes con su nombre o razón social.
SELECT 
    c.id AS cliente_id,
    c.tipo_cliente,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente
FROM clientes c
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY c.id;
GO

-- 2. Mostrar personas naturales con situación laboral.
SELECT 
    numero_documento,
    CONCAT(apellido_paterno, ' ', apellido_materno, ', ', nombres) AS nombre_completo,
    situacion_laboral
FROM personas_naturales
ORDER BY apellido_paterno, apellido_materno;
GO

-- 3. Mostrar empresas activas y su sector económico.
SELECT 
    ruc,
    razon_social,
    sector_economico,
    estado_empresa
FROM personas_juridicas
WHERE estado_empresa = 'Activo'
ORDER BY razon_social;
GO

-- 4. Listar cuentas en moneda PEN con saldo.
SELECT 
    num_cuenta,
    moneda,
    saldo
FROM cuentas
WHERE moneda = 'PEN'
ORDER BY saldo DESC;
GO

-- 5. Mostrar solicitudes del último año.
SELECT
    codigo_solicitud,
    fecha_solicitud,
    monto_solicitado,
    moneda_solicitada,
    estado
FROM solicitudes
WHERE fecha_solicitud >= DATEADD(YEAR, -1, GETDATE())
ORDER BY fecha_solicitud DESC;
GO

-- 6. Contar clientes por tipo.
SELECT
    CASE tipo_cliente WHEN 'N' THEN 'Persona Natural' ELSE 'Persona Jurídica' END AS tipo_cliente,
    COUNT(*) AS cantidad_clientes
FROM clientes
GROUP BY tipo_cliente;
GO

-- 7. Calcular saldo total por moneda.
SELECT
    moneda,
    SUM(saldo) AS saldo_total,
    AVG(saldo) AS saldo_promedio,
    COUNT(*) AS cantidad_cuentas
FROM cuentas
GROUP BY moneda
ORDER BY saldo_total DESC;
GO

-- 8. Mostrar cuántas cuentas tiene cada cliente.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    COUNT(cc.cuenta_id) AS cantidad_cuentas
FROM clientes c
LEFT JOIN cuentas_clientes cc ON cc.cliente_id = c.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY cantidad_cuentas DESC;
GO

-- 9. Total pagado por método de pago.
SELECT
    metodo_pago,
    COUNT(*) AS cantidad_pagos,
    SUM(monto) AS total_pagado
FROM pagos
GROUP BY metodo_pago
ORDER BY total_pagado DESC;
GO

-- 10. Promedio del score de riesgo por resultado de evaluación.
SELECT
    resultado,
    COUNT(*) AS cantidad_evaluaciones,
    AVG(score_riesgo) AS promedio_score,
    AVG(nivel_endeudamiento) AS promedio_endeudamiento
FROM evaluaciones_crediticias
GROUP BY resultado
ORDER BY promedio_score DESC;
GO

-----------------------------------------------------------
-- BLOQUE B: 10 CONSULTAS AVANZADAS Y EXPERTAS
-----------------------------------------------------------

-- 11. Clientes cuyo score de riesgo supera el promedio general.
SELECT DISTINCT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.score_riesgo
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE ec.score_riesgo > (SELECT AVG(score_riesgo) FROM evaluaciones_crediticias)
ORDER BY ec.score_riesgo DESC;
GO

-- 12. Créditos cuyo monto supera el promedio del producto solicitado.
SELECT
    cr.id AS credito_id,
    cr.numero_credito,
    pc.nombre AS producto,
    cr.monto
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN productos_crediticios pc ON pc.id = s.producto_crediticio_id
WHERE cr.monto >
(
    SELECT AVG(cr2.monto)
    FROM creditos cr2
    INNER JOIN evaluaciones_crediticias ec2 ON ec2.id = cr2.evaluacion_crediticia_id
    INNER JOIN solicitudes s2 ON s2.id = ec2.solicitud_id
    WHERE s2.producto_crediticio_id = s.producto_crediticio_id
)
ORDER BY cr.monto DESC;
GO

-- 13. Ranking de clientes por monto total desembolsado.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    SUM(cr.monto) AS total_desembolsado,
    DENSE_RANK() OVER (ORDER BY SUM(cr.monto) DESC) AS ranking_desembolso
FROM clientes c
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY ranking_desembolso;
GO

-- 14. Cuotas con saldo pendiente mayor al promedio de saldos pendientes.
SELECT
    id AS cuota_id,
    credito_id,
    num_cuota,
    saldo_cuota,
    AVG(saldo_cuota) OVER() AS promedio_saldo_pendiente
FROM cuotas
WHERE estado IN ('pendiente', 'pagada parcialmente')
  AND saldo_cuota >
  (
      SELECT AVG(saldo_cuota)
      FROM cuotas
      WHERE estado IN ('pendiente', 'pagada parcialmente')
  )
ORDER BY saldo_cuota DESC;
GO

-- 15. Clientes con cuentas en más de una moneda.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    COUNT(DISTINCT cu.moneda) AS cantidad_monedas
FROM clientes c
INNER JOIN cuentas_clientes cc ON cc.cliente_id = c.id
INNER JOIN cuentas cu ON cu.id = cc.cuenta_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
HAVING COUNT(DISTINCT cu.moneda) > 1
ORDER BY cantidad_monedas DESC;
GO

-- 16. Ratio de morosidad por crédito.
SELECT
    cr.id AS credito_id,
    cr.numero_credito,
    COUNT(q.id) AS total_cuotas,
    SUM(CASE WHEN q.estado = 'pendiente' THEN 1 ELSE 0 END) AS cuotas_pendientes,
    CAST(100.0 * SUM(CASE WHEN q.estado = 'pendiente' THEN 1 ELSE 0 END) / NULLIF(COUNT(q.id), 0) AS DECIMAL(10,2)) AS ratio_morosidad
FROM creditos cr
LEFT JOIN cuotas q ON q.credito_id = cr.id
GROUP BY cr.id, cr.numero_credito
ORDER BY ratio_morosidad DESC;
GO

-- 17. Clientes potencialmente sobreendeudados.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.deuda_activa + ec.deuda_activa_otras_entidades AS deuda_total,
    ec.ingresos_mensuales,
    CAST((ec.deuda_activa + ec.deuda_activa_otras_entidades) / NULLIF(ec.ingresos_mensuales, 0) AS DECIMAL(18,2)) AS ratio_sobreendeudamiento
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE (ec.deuda_activa + ec.deuda_activa_otras_entidades) / NULLIF(ec.ingresos_mensuales, 0) > 0.50
ORDER BY ratio_sobreendeudamiento DESC;
GO

-- 18. Concentración de cartera por producto.
SELECT
    pc.nombre AS producto,
    SUM(cr.monto) AS total_desembolsado,
    CAST(100.0 * SUM(cr.monto) / NULLIF((SELECT SUM(monto) FROM creditos), 0) AS DECIMAL(10,2)) AS participacion_porcentaje
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN productos_crediticios pc ON pc.id = s.producto_crediticio_id
GROUP BY pc.nombre
ORDER BY participacion_porcentaje DESC;
GO

-- 19. Semáforo crediticio por cliente.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.score_riesgo,
    CASE 
        WHEN ec.score_riesgo > 700 THEN 'Verde'
        WHEN ec.score_riesgo BETWEEN 500 AND 700 THEN 'Amarillo'
        ELSE 'Rojo'
    END AS semaforo_crediticio
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY ec.score_riesgo DESC;
GO

-- 20. Dashboard general de indicadores en una única consulta.
SELECT
    (SELECT COUNT(*) FROM clientes) AS total_clientes,
    (SELECT COUNT(*) FROM solicitudes) AS total_solicitudes,
    (SELECT COUNT(*) FROM creditos) AS total_creditos,
    (SELECT SUM(monto) FROM creditos) AS total_desembolsado,
    (SELECT SUM(monto) FROM pagos) AS total_pagos,
    (SELECT COUNT(*) FROM cuotas) AS total_cuotas,
    (
        SELECT CAST(100.0 * SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2))
        FROM cuotas
    ) AS ratio_morosidad;
GO
