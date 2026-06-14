USE pdan_bd_sistema_riesgo_crediticio;
GO

/*
===========================================================
6. EJERCICIOS PROPUESTOS DE CLASE PENDIENTES
Se identificó que el archivo Examples_expert.sql contenía el enunciado
de 20 ejercicios, pero solo algunos tenían solución escrita.
Este archivo completa los ejercicios 1 al 20 y añade los bonus.
===========================================================
*/

-----------------------------------------------------------
-- UTILIDAD: patrón de nombre de cliente usado en las consultas
-----------------------------------------------------------

-- EJERCICIO 1. Score crediticio simplificado y clasificación.
;WITH scores AS
(
    SELECT
        ec.id,
        ec.solicitud_id,
        ec.score_riesgo,
        ec.ingresos_mensuales,
        ec.nivel_endeudamiento,
        (ec.score_riesgo * 0.5)
        + ((ec.ingresos_mensuales / 1000.0) * 0.3)
        - (ec.nivel_endeudamiento * 0.2) AS score_final
    FROM evaluaciones_crediticias ec
)
SELECT
    s.id AS solicitud_id,
    sc.score_riesgo,
    sc.ingresos_mensuales,
    sc.nivel_endeudamiento,
    CAST(sc.score_final AS DECIMAL(18,2)) AS score_final,
    CASE
        WHEN sc.score_final < 200 THEN 'Alto Riesgo'
        WHEN sc.score_final < 400 THEN 'Riesgo Medio'
        ELSE 'Riesgo Bajo'
    END AS clasificacion
FROM scores sc
INNER JOIN solicitudes s ON s.id = sc.solicitud_id
ORDER BY score_final DESC;
GO

-- EJERCICIO 2. Tasa de aprobación de solicitudes.
SELECT
    COUNT(*) AS total_solicitudes,
    SUM(CASE WHEN estado = 'aprobada' THEN 1 ELSE 0 END) AS total_aprobadas,
    CAST(100.0 * SUM(CASE WHEN estado = 'aprobada' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS porcentaje_aprobacion
FROM solicitudes;
GO

-- EJERCICIO 3. Ratio de morosidad.
SELECT
    COUNT(*) AS total_cuotas,
    SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) AS cuotas_pendientes,
    CAST(100.0 * SUM(CASE WHEN estado = 'pendiente' THEN 1 ELSE 0 END) / NULLIF(COUNT(*), 0) AS DECIMAL(10,2)) AS ratio_morosidad
FROM cuotas;
GO

-- EJERCICIO 4. Clientes de alto riesgo.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.score_riesgo,
    ec.nivel_endeudamiento,
    ec.deuda_activa_otras_entidades AS deuda_externa
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE ec.score_riesgo < 500
  AND ec.nivel_endeudamiento > 70
  AND ec.deuda_activa_otras_entidades > 20000
ORDER BY ec.score_riesgo ASC;
GO

-- EJERCICIO 5. Ranking de exposición crediticia.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    cr.saldo_credito,
    ec.deuda_activa,
    ec.deuda_activa_otras_entidades,
    cr.saldo_credito + ec.deuda_activa + ec.deuda_activa_otras_entidades AS exposicion,
    DENSE_RANK() OVER (ORDER BY cr.saldo_credito + ec.deuda_activa + ec.deuda_activa_otras_entidades DESC) AS ranking_exposicion
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY exposicion DESC;
GO

-- EJERCICIO 6. Señales tempranas de incumplimiento.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    COUNT(q.id) AS numero_cuotas_pendientes,
    MIN(ec.score_riesgo) AS score_riesgo
FROM clientes c
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
INNER JOIN cuotas q ON q.credito_id = cr.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE q.estado = 'pendiente'
  AND ec.score_riesgo < 600
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
HAVING COUNT(q.id) > 3
ORDER BY numero_cuotas_pendientes DESC;
GO

-- EJERCICIO 7. Ingreso mensual recomendado.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    SUM(CASE WHEN q.estado IN ('pendiente', 'pagada parcialmente') THEN q.saldo_cuota ELSE 0 END) AS cuotas_activas,
    SUM(CASE WHEN q.estado IN ('pendiente', 'pagada parcialmente') THEN q.saldo_cuota ELSE 0 END) * 3 AS ingreso_recomendado
FROM clientes c
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
INNER JOIN cuotas q ON q.credito_id = cr.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY ingreso_recomendado DESC;
GO

-- EJERCICIO 8. Concentración de cartera por producto.
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

-- EJERCICIO 9. Porcentaje de utilización de línea.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.linea_credito,
    ec.deuda_activa,
    CAST(100.0 * ec.deuda_activa / NULLIF(ec.linea_credito, 0) AS DECIMAL(10,2)) AS utilizacion_porcentaje
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY utilizacion_porcentaje DESC;
GO

-- EJERCICIO 10. Clientes potencialmente sobreendeudados.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.deuda_activa + ec.deuda_activa_otras_entidades AS deuda_total,
    ec.ingresos_mensuales,
    CAST((ec.deuda_activa + ec.deuda_activa_otras_entidades) / NULLIF(ec.ingresos_mensuales, 0) AS DECIMAL(18,2)) AS ratio_deuda_ingreso
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE (ec.deuda_activa + ec.deuda_activa_otras_entidades) / NULLIF(ec.ingresos_mensuales, 0) > 0.50
ORDER BY ratio_deuda_ingreso DESC;
GO

-- EJERCICIO 11. Ranking de empresas por exposición financiera.
SELECT
    pj.ruc,
    pj.razon_social,
    SUM(cr.saldo_credito + ec.deuda_activa + ec.deuda_activa_otras_entidades) AS exposicion_financiera,
    DENSE_RANK() OVER (ORDER BY SUM(cr.saldo_credito + ec.deuda_activa + ec.deuda_activa_otras_entidades) DESC) AS ranking
FROM personas_juridicas pj
INNER JOIN clientes c ON c.id = pj.cliente_id
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
GROUP BY pj.ruc, pj.razon_social
ORDER BY ranking;
GO

-- EJERCICIO 12. Clientes con cuentas bancarias, pero sin solicitudes de crédito.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    COUNT(cc.cuenta_id) AS numero_cuentas
FROM clientes c
INNER JOIN cuentas_clientes cc ON cc.cliente_id = c.id
LEFT JOIN solicitudes s ON s.cliente_id = c.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE s.id IS NULL
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY numero_cuentas DESC;
GO

-- EJERCICIO 13. Clientes con créditos, pero sin pagos registrados.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    cr.numero_credito,
    cr.monto
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN cuotas q ON q.credito_id = cr.id
LEFT JOIN detalle_cuotas_pagos d ON d.cuota_id = q.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres, cr.numero_credito, cr.monto
HAVING COUNT(d.id) = 0
ORDER BY cr.monto DESC;
GO

-- EJERCICIO 14. Anomalías crediticias: monto crédito mayor que patrimonio.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.valor_patrimonio AS patrimonio,
    cr.monto AS monto_credito
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE cr.monto > ec.valor_patrimonio
ORDER BY cr.monto DESC;
GO

-- EJERCICIO 15. Clientes con patrimonio comprometido.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.valor_patrimonio,
    ec.deuda_activa + ec.deuda_activa_otras_entidades AS deuda_total,
    ec.valor_patrimonio - (ec.deuda_activa + ec.deuda_activa_otras_entidades) AS patrimonio_neto_simulado
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE ec.valor_patrimonio - (ec.deuda_activa + ec.deuda_activa_otras_entidades) < 0
ORDER BY patrimonio_neto_simulado ASC;
GO

-- EJERCICIO 16. Dashboard general en una única consulta.
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

-- EJERCICIO 17. Tendencia mensual de solicitudes.
SELECT
    YEAR(fecha_solicitud) AS anio,
    MONTH(fecha_solicitud) AS mes,
    COUNT(*) AS cantidad_solicitudes
FROM solicitudes
GROUP BY YEAR(fecha_solicitud), MONTH(fecha_solicitud)
ORDER BY anio, mes;
GO

-- EJERCICIO 18. Mes con mayor desembolso.
SELECT
    YEAR(fecha_desembolso) AS anio,
    MONTH(fecha_desembolso) AS mes,
    SUM(monto) AS total_desembolsado
FROM creditos
GROUP BY YEAR(fecha_desembolso), MONTH(fecha_desembolso)
ORDER BY total_desembolsado DESC;
GO

-- EJERCICIO 19. Proyección de ingresos futuros por intereses.
SELECT
    cr.id AS credito_id,
    cr.numero_credito,
    SUM(q.intereses) AS intereses_pendientes,
    SUM(q.saldo_cuota) AS total_proyectado
FROM creditos cr
INNER JOIN cuotas q ON q.credito_id = cr.id
WHERE q.estado IN ('pendiente', 'pagada parcialmente')
GROUP BY cr.id, cr.numero_credito
ORDER BY total_proyectado DESC;
GO

-- EJERCICIO 20. Semáforo crediticio.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    ec.score_riesgo,
    CASE
        WHEN ec.score_riesgo > 700 THEN 'Verde'
        WHEN ec.score_riesgo BETWEEN 500 AND 700 THEN 'Amarillo'
        ELSE 'Rojo'
    END AS semaforo
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY ec.score_riesgo DESC;
GO

-----------------------------------------------------------
-- BONUS
-----------------------------------------------------------

-- BONUS 1. Top 10 clientes con mayor deuda consolidada.
SELECT TOP (10)
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    cr.saldo_credito + ec.deuda_activa + ec.deuda_activa_otras_entidades AS deuda_consolidada
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
ORDER BY deuda_consolidada DESC;
GO

-- BONUS 2. Ranking con DENSE_RANK por monto total desembolsado.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    SUM(cr.monto) AS total_desembolsado,
    DENSE_RANK() OVER (ORDER BY SUM(cr.monto) DESC) AS ranking
FROM clientes c
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY ranking;
GO

-- BONUS 3. Clasificación ABC de clientes por monto total de créditos.
;WITH cartera AS
(
    SELECT
        c.id AS cliente_id,
        COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
        SUM(cr.monto) AS total_creditos
    FROM clientes c
    INNER JOIN solicitudes s ON s.cliente_id = c.id
    INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
    INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
    LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
    LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
    GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
),
ranking AS
(
    SELECT
        *,
        CUME_DIST() OVER (ORDER BY total_creditos DESC) AS porcentaje_acumulado
    FROM cartera
)
SELECT
    cliente_id,
    cliente,
    total_creditos,
    CASE
        WHEN porcentaje_acumulado <= 0.20 THEN 'A'
        WHEN porcentaje_acumulado <= 0.50 THEN 'B'
        ELSE 'C'
    END AS clasificacion_abc
FROM ranking
ORDER BY total_creditos DESC;
GO

-- BONUS 4. Clientes con riesgo de refinanciación.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    cr.numero_credito,
    cr.monto,
    cr.saldo_credito,
    COUNT(q.id) AS cuotas_pendientes
FROM creditos cr
INNER JOIN evaluaciones_crediticias ec ON ec.id = cr.evaluacion_crediticia_id
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
INNER JOIN clientes c ON c.id = s.cliente_id
INNER JOIN cuotas q ON q.credito_id = cr.id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
WHERE q.estado = 'pendiente'
  AND cr.saldo_credito > cr.monto * 0.50
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres, cr.numero_credito, cr.monto, cr.saldo_credito
HAVING COUNT(q.id) > 5
ORDER BY cuotas_pendientes DESC;
GO

-- BONUS 5. Reporte ejecutivo.
SELECT
    c.id AS cliente_id,
    COALESCE(pj.razon_social, CONCAT(pn.apellido_paterno, ' ', pn.apellido_materno, ', ', pn.nombres)) AS cliente,
    COUNT(DISTINCT cr.id) AS numero_creditos,
    SUM(cr.monto) AS total_desembolsado,
    ISNULL(SUM(p.monto), 0) AS total_pagado,
    SUM(cr.saldo_credito) AS saldo_pendiente,
    AVG(ec.score_riesgo) AS score_riesgo_promedio,
    AVG(ec.nivel_endeudamiento) AS nivel_endeudamiento_promedio
FROM clientes c
INNER JOIN solicitudes s ON s.cliente_id = c.id
INNER JOIN evaluaciones_crediticias ec ON ec.solicitud_id = s.id
INNER JOIN creditos cr ON cr.evaluacion_crediticia_id = ec.id
LEFT JOIN cuotas q ON q.credito_id = cr.id
LEFT JOIN detalle_cuotas_pagos d ON d.cuota_id = q.id
LEFT JOIN pagos p ON p.id = d.pago_id
LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id AND c.tipo_cliente = 'N'
LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id AND c.tipo_cliente = 'J'
GROUP BY c.id, pj.razon_social, pn.apellido_paterno, pn.apellido_materno, pn.nombres
ORDER BY saldo_pendiente DESC;
GO
