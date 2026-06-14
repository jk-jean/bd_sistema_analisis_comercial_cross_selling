USE pdan_bd_sistema_riesgo_crediticio;
GO

-- 1) CLIENTES: 40 registros base: 25 naturales y 15 jurídicos
;WITH numeros AS
(
    SELECT TOP (40)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects
)
INSERT INTO clientes (tipo_cliente)
SELECT CASE WHEN n <= 25 THEN 'N' ELSE 'J' END
FROM numeros;
GO

-- 2) PERSONAS NATURALES: 25 registros dependientes de clientes N
;WITH clientes_n AS
(
    SELECT 
        c.id AS cliente_id,
        ROW_NUMBER() OVER (ORDER BY c.id) AS rn
    FROM clientes c
    LEFT JOIN personas_naturales pn ON pn.cliente_id = c.id
    WHERE c.tipo_cliente = 'N'
      AND pn.id IS NULL
)
INSERT INTO personas_naturales
(
    numero_documento, nombres, apellido_paterno, apellido_materno,
    celular, direccion, ubigeo, fecha_nacimiento, estado_civil,
    genero, situacion_laboral, cliente_id
)
SELECT
    RIGHT('00000000' + CAST(70000000 + cliente_id AS VARCHAR(8)), 8),
    CONCAT('ClienteN', rn),
    CONCAT('ApellidoP', rn),
    CONCAT('ApellidoM', rn),
    CONCAT('9', RIGHT('00000000' + CAST(10000000 + cliente_id AS VARCHAR(8)), 8)),
    CONCAT('Av. Principal ', rn),
    RIGHT('000000' + CAST(150000 + rn AS VARCHAR(6)), 6),
    DATEADD(YEAR, -1 * (20 + (rn % 35)), CAST(GETDATE() AS DATE)),
    CASE rn % 3 WHEN 0 THEN 'S' WHEN 1 THEN 'C' ELSE 'D' END,
    CASE rn % 2 WHEN 0 THEN 'M' ELSE 'F' END,
    CASE rn % 4 WHEN 0 THEN 'Empleado'
                WHEN 1 THEN 'Independiente'
                WHEN 2 THEN 'Desempleado'
                ELSE 'No consigna' END,
    cliente_id
FROM clientes_n
WHERE rn <= 25;
GO

-- 3) PERSONAS JURÍDICAS: 15 registros dependientes de clientes J
;WITH clientes_j AS
(
    SELECT 
        c.id AS cliente_id,
        ROW_NUMBER() OVER (ORDER BY c.id) AS rn
    FROM clientes c
    LEFT JOIN personas_juridicas pj ON pj.cliente_id = c.id
    WHERE c.tipo_cliente = 'J'
      AND pj.id IS NULL
)
INSERT INTO personas_juridicas
(
    ruc, razon_social, nombre_comercial, tipo_empresa, representante_legal,
    sector_economico, direccion, ubigeo, telefono, correo,
    fecha_constitucion, estado_empresa, inicio_actividades,
    numero_empleados, cliente_id
)
SELECT
    CONCAT('20', RIGHT('000000000' + CAST(100000000 + cliente_id AS VARCHAR(9)), 9)),
    CONCAT('Empresa ', rn, ' SAC'),
    CONCAT('Comercial ', rn),
    CASE rn % 5 WHEN 0 THEN 'SA'
                WHEN 1 THEN 'SAC'
                WHEN 2 THEN 'SRL'
                WHEN 3 THEN 'EIRL'
                ELSE 'SAA' END,
    CONCAT('Representante ', rn),
    CASE rn % 5 WHEN 0 THEN 'Comercio'
                WHEN 1 THEN 'Servicios'
                WHEN 2 THEN 'Construcción'
                WHEN 3 THEN 'Tecnología'
                ELSE 'Industria' END,
    CONCAT('Jr. Empresa ', rn),
    RIGHT('000000' + CAST(150100 + rn AS VARCHAR(6)), 6),
    CONCAT('01', RIGHT('0000000' + CAST(5000000 + rn AS VARCHAR(7)), 7)),
    CONCAT('empresa', rn, '@correo.com'),
    DATEADD(YEAR, -1 * (3 + (rn % 20)), CAST(GETDATE() AS DATE)),
    CASE WHEN rn % 6 = 0 THEN 'Suspendido' ELSE 'Activo' END,
    DATEADD(YEAR, -1 * (2 + (rn % 18)), CAST(GETDATE() AS DATE)),
    5 + (rn * 3),
    cliente_id
FROM clientes_j
WHERE rn <= 15;
GO

-- 4) TIPOS DE CUENTA: mínimo 5 registros
INSERT INTO tipos_cuenta (nombre, descripcion)
SELECT v.nombre, v.descripcion
FROM
(
    VALUES
    ('Cuenta Ahorro', 'Cuenta de ahorro para personas naturales'),
    ('Cuenta Corriente', 'Cuenta para operaciones frecuentes'),
    ('Cuenta Sueldo', 'Cuenta para depósitos de planilla'),
    ('Cuenta CTS', 'Cuenta de compensación por tiempo de servicio'),
    ('Cuenta Empresarial', 'Cuenta para empresas'),
    ('Cuenta Premium', 'Cuenta para clientes preferentes')
) v(nombre, descripcion)
WHERE NOT EXISTS
(
    SELECT 1 FROM tipos_cuenta tc WHERE tc.nombre = v.nombre
);
GO

-- 5) PRODUCTOS CREDITICIOS: mínimo 5 registros
INSERT INTO productos_crediticios
(
    nombre, monto_minimo, monto_maximo,
    tasa_interes_minima, tasa_interes_maxima,
    plazo_minimo_meses, plazo_maximo_meses,
    estado, created_at, updated_at
)
SELECT *
FROM
(
    VALUES
    ('Prestamo Personal', 1000.00, 50000.00, 10.50, 35.00, 6, 60, 'activo', GETDATE(), GETDATE()),
    ('Credito Hipotecario', 50000.00, 500000.00, 7.50, 15.00, 60, 360, 'activo', GETDATE(), GETDATE()),
    ('Credito Vehicular', 10000.00, 120000.00, 8.50, 18.00, 12, 72, 'activo', GETDATE(), GETDATE()),
    ('Linea de Credito', 3000.00, 80000.00, 12.00, 25.00, 12, 48, 'activo', GETDATE(), GETDATE()),
    ('Credito Empresarial', 10000.00, 1000000.00, 9.50, 22.00, 12, 120, 'activo', GETDATE(), GETDATE())
) v(nombre, monto_minimo, monto_maximo, tasa_interes_minima, tasa_interes_maxima,
    plazo_minimo_meses, plazo_maximo_meses, estado, created_at, updated_at)
WHERE NOT EXISTS
(
    SELECT 1 FROM productos_crediticios pc WHERE pc.nombre = v.nombre
);
GO

-----------------------------------------------------------
-- B. TABLAS RELACIONALES / TRANSACCIONALES
-----------------------------------------------------------

-- 6) CUENTAS: 100 registros
;WITH numeros AS
(
    SELECT TOP (100)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
),
tipos AS
(
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn, COUNT(*) OVER() AS total
    FROM tipos_cuenta
)
INSERT INTO cuentas
(
    num_cuenta, cci, num_tarjeta, fecha_creacion,
    moneda, saldo, tipo_cuenta_id
)
SELECT
    CONCAT('104500', RIGHT('000000' + CAST(n.n AS VARCHAR(6)), 6)),
    CONCAT('002104500', RIGHT('000000' + CAST(n.n AS VARCHAR(6)), 6)),
    CONCAT('453212345678', RIGHT('0000' + CAST(n.n AS VARCHAR(4)), 4)),
    DATEADD(DAY, -1 * (n.n % 700), GETDATE()),
    CASE n.n % 3 WHEN 0 THEN 'PEN' WHEN 1 THEN 'USD' ELSE 'EUR' END,
    CAST(500 + (n.n * 350.75) AS DECIMAL(18,2)),
    t.id
FROM numeros n
INNER JOIN tipos t ON t.rn = ((n.n - 1) % t.total) + 1
WHERE NOT EXISTS
(
    SELECT 1 
    FROM cuentas c 
    WHERE c.num_cuenta = CONCAT('104500', RIGHT('000000' + CAST(n.n AS VARCHAR(6)), 6))
);
GO

-- 7) CUENTAS_CLIENTES: 100 relaciones
;WITH cuentas_n AS
(
    SELECT c.id AS cuenta_id, ROW_NUMBER() OVER (ORDER BY c.id) AS rn
    FROM cuentas c
),
clientes_n AS
(
    SELECT c.id AS cliente_id, ROW_NUMBER() OVER (ORDER BY c.id) AS rn, COUNT(*) OVER() AS total
    FROM clientes c
)
INSERT INTO cuentas_clientes (cliente_id, cuenta_id)
SELECT cli.cliente_id, cu.cuenta_id
FROM cuentas_n cu
INNER JOIN clientes_n cli ON cli.rn = ((cu.rn - 1) % cli.total) + 1
WHERE NOT EXISTS
(
    SELECT 1 
    FROM cuentas_clientes cc
    WHERE cc.cliente_id = cli.cliente_id
      AND cc.cuenta_id = cu.cuenta_id
);
GO

-- 8) SOLICITUDES: 80 registros
;WITH numeros AS
(
    SELECT TOP (80)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
),
clientes_n AS
(
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn, COUNT(*) OVER() AS total
    FROM clientes
),
productos_n AS
(
    SELECT id, ROW_NUMBER() OVER (ORDER BY id) AS rn, COUNT(*) OVER() AS total
    FROM productos_crediticios
)
INSERT INTO solicitudes
(
    cliente_id, producto_crediticio_id, codigo_solicitud,
    fecha_solicitud, monto_solicitado, moneda_solicitada, estado
)
SELECT
    cli.id,
    prod.id,
    CONCAT('SOL-', RIGHT('00000' + CAST(n.n AS VARCHAR(5)), 5)),
    DATEADD(DAY, -1 * (n.n % 365), GETDATE()),
    CAST(3000 + (n.n * 1125.50) AS DECIMAL(18,2)),
    CASE n.n % 3 WHEN 0 THEN 'PEN' WHEN 1 THEN 'USD' ELSE 'EUR' END,
    CASE n.n % 4 WHEN 0 THEN 'ingresado'
                 WHEN 1 THEN 'en evaluacion'
                 WHEN 2 THEN 'aprobada'
                 ELSE 'desestimado' END
FROM numeros n
INNER JOIN clientes_n cli ON cli.rn = ((n.n - 1) % cli.total) + 1
INNER JOIN productos_n prod ON prod.rn = ((n.n - 1) % prod.total) + 1
WHERE NOT EXISTS
(
    SELECT 1 
    FROM solicitudes s 
    WHERE s.codigo_solicitud = CONCAT('SOL-', RIGHT('00000' + CAST(n.n AS VARCHAR(5)), 5))
);
GO

-- 9) EVALUACIONES CREDITICIAS: una por solicitud
INSERT INTO evaluaciones_crediticias
(
    solicitud_id, score_riesgo, nivel_endeudamiento,
    deuda_activa, deuda_activa_otras_entidades,
    linea_credito, linea_credito_otras_entidades,
    valor_patrimonio, ingresos_mensuales, resultado
)
SELECT
    s.id,
    CAST(300 + (s.id % 600) AS DECIMAL(10,2)),
    CAST(10 + (s.id % 85) AS DECIMAL(10,2)),
    CAST(1000 + (s.id * 420.00) AS DECIMAL(18,2)),
    CAST(500 + (s.id * 280.00) AS DECIMAL(18,2)),
    CAST(10000 + (s.id * 900.00) AS DECIMAL(18,2)),
    CAST(5000 + (s.id * 550.00) AS DECIMAL(18,2)),
    CAST(25000 + (s.id * 2500.00) AS DECIMAL(18,2)),
    CAST(1200 + (s.id * 95.00) AS DECIMAL(18,2)),
    CASE WHEN s.estado = 'aprobada' THEN 'Aprobado'
         WHEN s.estado = 'desestimado' THEN 'Rechazado'
         WHEN s.estado = 'en evaluacion' THEN 'En análisis'
         ELSE 'Pendiente' END
FROM solicitudes s
WHERE NOT EXISTS
(
    SELECT 1 
    FROM evaluaciones_crediticias ec 
    WHERE ec.solicitud_id = s.id
);
GO

-- 10) CRÉDITOS: mínimo 20 registros, basados en evaluaciones aprobadas
INSERT INTO creditos
(
    evaluacion_crediticia_id, cuenta_id, monto, plazo_meses,
    tea, tcea, valor_cuota, fecha_inicio, fecha_fin,
    fecha_desembolso, numero_credito, fecha_vencimiento,
    estado, saldo_credito, desgravamen
)
SELECT
    ec.id,
    ca.cuenta_id,
    s.monto_solicitado,
    12 + (ec.id % 48),
    CAST(8 + (ec.id % 15) AS DECIMAL(10,2)),
    CAST(10 + (ec.id % 18) AS DECIMAL(10,2)),
    CAST(s.monto_solicitado / (12 + (ec.id % 48)) AS DECIMAL(18,2)),
    CAST(DATEADD(DAY, 5, s.fecha_solicitud) AS DATE),
    CAST(DATEADD(MONTH, 12 + (ec.id % 48), DATEADD(DAY, 5, s.fecha_solicitud)) AS DATE),
    DATEADD(DAY, 5, s.fecha_solicitud),
    100000 + ec.id,
    CAST(DATEADD(MONTH, 12 + (ec.id % 48), DATEADD(DAY, 5, s.fecha_solicitud)) AS DATE),
    CASE WHEN ec.id % 5 = 0 THEN 'desembolsado' ELSE 'vigente' END,
    s.monto_solicitado,
    CAST(s.monto_solicitado * 0.015 AS DECIMAL(18,2))
FROM evaluaciones_crediticias ec
INNER JOIN solicitudes s ON s.id = ec.solicitud_id
CROSS APPLY
(
    SELECT TOP (1) cc.cuenta_id
    FROM cuentas_clientes cc
    WHERE cc.cliente_id = s.cliente_id
    ORDER BY cc.cuenta_id
) ca
WHERE ec.resultado = 'Aprobado'
  AND NOT EXISTS
  (
      SELECT 1 
      FROM creditos c 
      WHERE c.evaluacion_crediticia_id = ec.id
  );
GO

-- 11) CUOTAS: muchas más de 20, según plazo de cada crédito
;WITH numeros AS
(
    SELECT TOP (360)
        ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS n
    FROM sys.objects a
    CROSS JOIN sys.objects b
)
INSERT INTO cuotas
(
    credito_id, num_cuota, fecha_vencimiento, capital, intereses,
    seguros, total_cuota, estado, tasa_mora, saldo_cuota
)
SELECT
    c.id,
    n.n,
    DATEADD(MONTH, n.n, c.fecha_inicio),
    valores.capital,
    valores.intereses,
    valores.seguros,
    valores.capital + valores.intereses + valores.seguros,
    estado.estado_cuota,
    CAST(2 + (n.n % 8) AS DECIMAL(10,2)),
    CASE 
        WHEN estado.estado_cuota = 'pendiente'
            THEN valores.capital + valores.intereses + valores.seguros
        WHEN estado.estado_cuota = 'pagada parcialmente'
            THEN CAST((valores.capital + valores.intereses + valores.seguros) * 0.40 AS DECIMAL(18,2))
        ELSE 0 
    END
FROM creditos c
INNER JOIN numeros n ON n.n <= c.plazo_meses
CROSS APPLY
(
    SELECT
        CAST(c.valor_cuota * 0.80 AS DECIMAL(18,2)) AS capital,
        CAST(c.valor_cuota * 0.15 AS DECIMAL(18,2)) AS intereses,
        CAST(c.valor_cuota * 0.05 AS DECIMAL(18,2)) AS seguros
) valores
CROSS APPLY
(
    SELECT CASE n.n % 4 WHEN 0 THEN 'pendiente'
                        WHEN 1 THEN 'pagada parcialmente'
                        ELSE 'pagada' END AS estado_cuota
) estado
WHERE NOT EXISTS
(
    SELECT 1 
    FROM cuotas q 
    WHERE q.credito_id = c.id
      AND q.num_cuota = n.n
);
GO

-- 12) PAGOS: mínimo 20 pagos generados desde cuotas pagadas/parcialmente pagadas
INSERT INTO pagos
(
    num_operacion, monto, fecha_pago, metodo_pago, observaciones
)
SELECT
    CONCAT('OP-', RIGHT('000000' + CAST(q.id AS VARCHAR(6)), 6)),
    CASE WHEN q.estado = 'pagada' THEN q.total_cuota
         WHEN q.estado = 'pagada parcialmente' THEN q.total_cuota - q.saldo_cuota
    END,
    DATEADD(DAY, q.id % 10, q.fecha_vencimiento),
    CASE q.id % 4 WHEN 0 THEN 'Transferencia'
                  WHEN 1 THEN 'Yape'
                  WHEN 2 THEN 'Tarjeta'
                  ELSE 'Ventanilla' END,
    'Pago automático generado'
FROM cuotas q
WHERE q.estado <> 'pendiente'
  AND NOT EXISTS
  (
      SELECT 1
      FROM pagos p
      WHERE p.num_operacion = CONCAT('OP-', RIGHT('000000' + CAST(q.id AS VARCHAR(6)), 6))
  );
GO

-- 13) DETALLE_CUOTAS_PAGOS: relaciones de pago con cuota
INSERT INTO detalle_cuotas_pagos
(
    cuota_id, pago_id, monto_pagado
)
SELECT
    q.id,
    p.id,
    p.monto
FROM cuotas q
INNER JOIN pagos p
    ON p.num_operacion = CONCAT('OP-', RIGHT('000000' + CAST(q.id AS VARCHAR(6)), 6))
WHERE q.estado <> 'pendiente'
  AND NOT EXISTS
  (
      SELECT 1
      FROM detalle_cuotas_pagos d
      WHERE d.cuota_id = q.id
        AND d.pago_id = p.id
  );
GO

-----------------------------------------------------------
-- VALIDACIÓN DE CANTIDADES
-----------------------------------------------------------
SELECT 'clientes' AS tabla, COUNT(*) AS registros FROM clientes
UNION ALL SELECT 'personas_naturales', COUNT(*) FROM personas_naturales
UNION ALL SELECT 'personas_juridicas', COUNT(*) FROM personas_juridicas
UNION ALL SELECT 'tipos_cuenta', COUNT(*) FROM tipos_cuenta
UNION ALL SELECT 'productos_crediticios', COUNT(*) FROM productos_crediticios
UNION ALL SELECT 'cuentas', COUNT(*) FROM cuentas
UNION ALL SELECT 'cuentas_clientes', COUNT(*) FROM cuentas_clientes
UNION ALL SELECT 'solicitudes', COUNT(*) FROM solicitudes
UNION ALL SELECT 'evaluaciones_crediticias', COUNT(*) FROM evaluaciones_crediticias
UNION ALL SELECT 'creditos', COUNT(*) FROM creditos
UNION ALL SELECT 'cuotas', COUNT(*) FROM cuotas
UNION ALL SELECT 'pagos', COUNT(*) FROM pagos
UNION ALL SELECT 'detalle_cuotas_pagos', COUNT(*) FROM detalle_cuotas_pagos;
GO
