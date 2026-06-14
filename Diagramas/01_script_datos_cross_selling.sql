/* ==========================================================
   SCRIPT CON DATOS - BD SISTEMA ANALISIS COMERCIAL CROSS SELLING
   Base de datos: bd_sistema_analisis_comercial_cross_selling
   Ejecutar despues de crear la base de datos y sus tablas.
   Incluye limpieza para poder volver a ejecutar el script.
   ========================================================== */

USE bd_sistema_analisis_comercial_cross_selling;
GO

SET NOCOUNT ON;
GO

/* Limpieza en orden correcto por claves foraneas */
DELETE FROM Conversion;
DELETE FROM Campania_cliente;
DELETE FROM Campania;
DELETE FROM Comportamiento_cliente;
DELETE FROM Producto_cliente;
DELETE FROM Cuenta;
DELETE FROM Cliente;
DELETE FROM Producto_financiero;
DELETE FROM Segmento;
GO

DBCC CHECKIDENT ('Conversion', RESEED, 1000);
DBCC CHECKIDENT ('Campania_cliente', RESEED, 1000);
DBCC CHECKIDENT ('Campania', RESEED, 1000);
DBCC CHECKIDENT ('Comportamiento_cliente', RESEED, 1000);
DBCC CHECKIDENT ('Producto_cliente', RESEED, 1000);
DBCC CHECKIDENT ('Cuenta', RESEED, 1000);
DBCC CHECKIDENT ('Cliente', RESEED, 1000);
DBCC CHECKIDENT ('Producto_financiero', RESEED, 1000);
DBCC CHECKIDENT ('Segmento', RESEED, 1000);
GO

/* TABLAS INDEPENDIENTES / MAESTRAS */
INSERT INTO Segmento (nombre_segmento, descripcion) VALUES
('Joven Digital', 'Clientes jovenes con alta interaccion digital'),
('Masivo', 'Clientes de ingresos medios con productos basicos'),
('Premium', 'Clientes de alto ingreso y mayor potencial comercial'),
('Emprendedor', 'Clientes independientes o con negocio propio'),
('Riesgo Controlado', 'Clientes con comportamiento irregular pero gestionable');
GO

INSERT INTO Producto_financiero
(nombre_producto, tipo_producto, descripcion, tasa_interes, comision, monto_maximo, monto_minimo, estado_producto) VALUES
('Cuenta Sueldo Plus', 'Cuenta', 'Cuenta para abono de remuneraciones', 0.50, 0.00, 50000.00, 1000.00, 'Activo'),
('Tarjeta Cashback', 'Tarjeta', 'Tarjeta de credito con devolucion por consumo', 35.90, 25.00, 30000.00, 1000.00, 'Activo'),
('Prestamo Personal Libre', 'Prestamo', 'Prestamo de libre disponibilidad', 28.50, 50.00, 80000.00, 2000.00, 'Activo'),
('Seguro Proteccion Total', 'Seguro', 'Seguro de vida y proteccion financiera', 0.00, 15.00, 20000.00, 1000.00, 'Activo'),
('Fondo Inversion Conservador', 'Inversion', 'Fondo para ahorro e inversion de bajo riesgo', 6.50, 10.00, 100000.00, 1000.00, 'Activo'),
('Credito Emprendedor', 'Credito', 'Financiamiento para capital de trabajo', 24.80, 80.00, 120000.00, 3000.00, 'Activo'),
('Cuenta Ahorro Digital', 'Cuenta', 'Cuenta de ahorro sin mantenimiento', 1.20, 0.00, 40000.00, 1000.00, 'Activo'),
('Tarjeta Travel Gold', 'Tarjeta', 'Tarjeta orientada a viajes y consumos premium', 32.00, 35.00, 60000.00, 5000.00, 'Activo');
GO

/* CLIENTES */
INSERT INTO Cliente
(dni, nombre, apellido, fecha_nacimiento, ingreso_mensual, situacion_laboral, distrito, fecha_alta, estado_cliente, id_segmento) VALUES
('70000001', 'Ana', 'Torres', '1998-04-12', 2800.00, 'Dependiente', 'Miraflores', '2024-01-15', 'Activo', 1001),
('70000002', 'Luis', 'Ramos', '1987-09-25', 4500.00, 'Dependiente', 'San Isidro', '2023-11-20', 'Activo', 1003),
('70000003', 'Maria', 'Lopez', '1995-06-03', 3200.00, 'Independiente', 'Surco', '2024-02-10', 'Activo', 1004),
('70000004', 'Carlos', 'Paredes', '1979-12-18', 6200.00, 'Dependiente', 'La Molina', '2023-08-09', 'Activo', 1003),
('70000005', 'Rosa', 'Vargas', '1992-07-21', 2500.00, 'Dependiente', 'Comas', '2024-03-01', 'Activo', 1002),
('70000006', 'Jorge', 'Castillo', '1985-03-30', 3900.00, 'Independiente', 'Los Olivos', '2022-12-12', 'Activo', 1004),
('70000007', 'Elena', 'Mendoza', '2000-10-05', 1800.00, 'Dependiente', 'Ate', '2024-04-11', 'Activo', 1001),
('70000008', 'Miguel', 'Herrera', '1976-01-14', 7200.00, 'Empresario', 'San Borja', '2021-09-19', 'Activo', 1003),
('70000009', 'Patricia', 'Flores', '1990-02-28', 3100.00, 'Dependiente', 'Chorrillos', '2023-05-16', 'Activo', 1002),
('70000010', 'Diego', 'Salazar', '1999-11-09', 2200.00, 'Dependiente', 'Villa El Salvador', '2024-05-02', 'Activo', 1001),
('70000011', 'Lucia', 'Campos', '1983-08-17', 5300.00, 'Independiente', 'Jesus Maria', '2022-07-07', 'Activo', 1004),
('70000012', 'Fernando', 'Reyes', '1974-05-06', 8500.00, 'Dependiente', 'San Isidro', '2021-03-22', 'Activo', 1003),
('70000013', 'Sofia', 'Aguilar', '1997-09-13', 2700.00, 'Dependiente', 'Breña', '2024-01-28', 'Activo', 1002),
('70000014', 'Ricardo', 'Navarro', '1989-04-19', 3600.00, 'Independiente', 'Callao', '2023-10-10', 'Observado', 1005),
('70000015', 'Gabriela', 'Fuentes', '1994-12-01', 4100.00, 'Dependiente', 'Pueblo Libre', '2023-06-30', 'Activo', 1002);
GO

/* CUENTAS: minimo 20 registros */
INSERT INTO Cuenta
(num_cuenta, tipo_cuenta, moneda, saldo_actual, fecha_apertura, estado_cuenta, id_cliente) VALUES
('00110000000000001001', 'Ahorro', 'PEN', 3500.00, '2024-01-16', 'Activa', 1001),
('00110000000000001002', 'Sueldo', 'PEN', 5200.00, '2023-11-21', 'Activa', 1002),
('00110000000000001003', 'Ahorro', 'PEN', 2100.00, '2024-02-11', 'Activa', 1003),
('00110000000000001004', 'Corriente', 'PEN', 9800.00, '2023-08-10', 'Activa', 1004),
('00110000000000001005', 'Ahorro', 'PEN', 1200.00, '2024-03-02', 'Activa', 1005),
('00110000000000001006', 'Corriente', 'PEN', 4300.00, '2022-12-13', 'Activa', 1006),
('00110000000000001007', 'Ahorro', 'PEN', 900.00, '2024-04-12', 'Activa', 1007),
('00110000000000001008', 'Corriente', 'USD', 2500.00, '2021-09-20', 'Activa', 1008),
('00110000000000001009', 'Ahorro', 'PEN', 1750.00, '2023-05-17', 'Activa', 1009),
('00110000000000001010', 'Ahorro', 'PEN', 800.00, '2024-05-03', 'Activa', 1010),
('00110000000000001011', 'Corriente', 'PEN', 6400.00, '2022-07-08', 'Activa', 1011),
('00110000000000001012', 'Sueldo', 'PEN', 11200.00, '2021-03-23', 'Activa', 1012),
('00110000000000001013', 'Ahorro', 'PEN', 2400.00, '2024-01-29', 'Activa', 1013),
('00110000000000001014', 'Ahorro', 'PEN', 650.00, '2023-10-11', 'Bloqueada', 1014),
('00110000000000001015', 'Sueldo', 'PEN', 4100.00, '2023-07-01', 'Activa', 1015),
('00110000000000001016', 'CTS', 'PEN', 2600.00, '2024-01-20', 'Activa', 1001),
('00110000000000001017', 'Ahorro', 'USD', 1800.00, '2023-12-05', 'Activa', 1002),
('00110000000000001018', 'Corriente', 'PEN', 3000.00, '2024-02-20', 'Activa', 1003),
('00110000000000001019', 'Ahorro', 'USD', 5200.00, '2023-09-01', 'Activa', 1004),
('00110000000000001020', 'Ahorro', 'PEN', 1500.00, '2024-03-15', 'Activa', 1005),
('00110000000000001021', 'Corriente', 'USD', 4100.00, '2022-12-20', 'Activa', 1006),
('00110000000000001022', 'Sueldo', 'PEN', 2300.00, '2024-05-10', 'Activa', 1010);
GO

/* PRODUCTOS CONTRATADOS: tabla transaccional con mas de 20 registros */
INSERT INTO Producto_cliente
(fecha_contratacion, monto_aprobado, monto_utilizado, saldo_actual, canal_contratacion, estado_producto_cliente, id_cliente, id_producto) VALUES
('2024-01-18', 10000, 2500, 2500, 'App', 'Activo', 1001, 1002),
('2024-01-19', 5000, 1000, 1000, 'Web', 'Activo', 1001, 1007),
('2023-12-01', 25000, 8000, 8000, 'Agencia', 'Activo', 1002, 1002),
('2024-01-05', 40000, 15000, 15000, 'Ejecutivo', 'Activo', 1002, 1005),
('2024-02-15', 12000, 4000, 4000, 'App', 'Activo', 1003, 1003),
('2024-02-18', 35000, 16000, 16000, 'Agencia', 'Activo', 1003, 1006),
('2023-08-20', 50000, 22000, 22000, 'Ejecutivo', 'Activo', 1004, 1008),
('2023-09-01', 70000, 32000, 32000, 'Ejecutivo', 'Activo', 1004, 1005),
('2024-03-05', 8000, 3000, 3000, 'Web', 'Activo', 1005, 1002),
('2024-03-08', 3000, 900, 900, 'App', 'Activo', 1005, 1004),
('2023-01-10', 45000, 18000, 18000, 'Agencia', 'Activo', 1006, 1006),
('2023-01-15', 10000, 4500, 4500, 'Web', 'Activo', 1006, 1002),
('2024-04-15', 6000, 1500, 1500, 'App', 'Activo', 1007, 1007),
('2021-10-01', 60000, 20000, 20000, 'Ejecutivo', 'Activo', 1008, 1008),
('2021-11-10', 90000, 50000, 50000, 'Ejecutivo', 'Activo', 1008, 1005),
('2023-06-02', 9000, 2000, 2000, 'Web', 'Activo', 1009, 1002),
('2024-05-06', 5000, 2200, 2200, 'App', 'Activo', 1010, 1002),
('2024-05-07', 4000, 600, 600, 'App', 'Activo', 1010, 1004),
('2022-07-20', 50000, 21000, 21000, 'Agencia', 'Activo', 1011, 1006),
('2022-08-03', 18000, 7500, 7500, 'Web', 'Activo', 1011, 1003),
('2021-04-10', 75000, 25000, 25000, 'Ejecutivo', 'Activo', 1012, 1008),
('2021-04-12', 100000, 45000, 45000, 'Ejecutivo', 'Activo', 1012, 1005),
('2024-02-01', 7000, 1800, 1800, 'App', 'Activo', 1013, 1002),
('2023-11-01', 6000, 5200, 5200, 'Agencia', 'Mora', 1014, 1002),
('2023-11-05', 15000, 13000, 13000, 'Agencia', 'Mora', 1014, 1003),
('2023-07-15', 15000, 3500, 3500, 'Web', 'Activo', 1015, 1002),
('2023-08-01', 25000, 5000, 5000, 'App', 'Activo', 1015, 1005);
GO

/* COMPORTAMIENTO CLIENTE: mas de 20 registros */
INSERT INTO Comportamiento_cliente
(periodo, cantidad_transaccion, monto_total_transaccion, saldo_promedio, nivel_actividad, id_cliente) VALUES
('2024-01-31', 18, 4200, 3100, 'Media', 1001),
('2024-02-29', 24, 5600, 3400, 'Alta', 1001),
('2024-03-31', 20, 4900, 3300, 'Media', 1001),
('2024-01-31', 35, 11000, 6200, 'Alta', 1002),
('2024-02-29', 42, 13500, 7000, 'Alta', 1002),
('2024-03-31', 40, 12500, 6800, 'Alta', 1002),
('2024-01-31', 14, 2600, 2000, 'Media', 1003),
('2024-02-29', 16, 3500, 2400, 'Media', 1003),
('2024-03-31', 22, 5100, 2800, 'Alta', 1003),
('2024-01-31', 48, 18000, 9000, 'Alta', 1004),
('2024-02-29', 51, 21000, 9500, 'Alta', 1004),
('2024-03-31', 45, 17500, 8700, 'Alta', 1004),
('2024-01-31', 8, 900, 1100, 'Baja', 1005),
('2024-02-29', 10, 1400, 1200, 'Baja', 1005),
('2024-03-31', 12, 1700, 1300, 'Media', 1005),
('2024-01-31', 26, 7500, 4200, 'Alta', 1006),
('2024-02-29', 21, 6400, 3900, 'Media', 1006),
('2024-03-31', 25, 6900, 4100, 'Alta', 1006),
('2024-01-31', 6, 650, 850, 'Baja', 1007),
('2024-02-29', 9, 1100, 900, 'Baja', 1007),
('2024-03-31', 11, 1350, 950, 'Media', 1007),
('2024-01-31', 55, 26000, 11800, 'Alta', 1008),
('2024-02-29', 60, 28000, 12600, 'Alta', 1008),
('2024-03-31', 58, 27500, 12300, 'Alta', 1008),
('2024-01-31', 13, 2300, 1600, 'Media', 1009),
('2024-02-29', 15, 2600, 1700, 'Media', 1009),
('2024-03-31', 17, 3100, 1800, 'Media', 1009),
('2024-01-31', 7, 800, 700, 'Baja', 1010),
('2024-02-29', 8, 950, 850, 'Baja', 1010),
('2024-03-31', 10, 1200, 900, 'Baja', 1010),
('2024-03-31', 33, 9200, 6100, 'Alta', 1011),
('2024-03-31', 61, 31000, 13000, 'Alta', 1012),
('2024-03-31', 16, 2700, 2200, 'Media', 1013),
('2024-03-31', 5, 500, 600, 'Baja', 1014),
('2024-03-31', 23, 5200, 3900, 'Alta', 1015);
GO

/* CAMPANIAS */
INSERT INTO Campania
(nombre_campania, fecha_inicio, fecha_fin, canal_principal, presupuesto, objetivo, estado_campania, id_producto) VALUES
('Cross Tarjeta Cashback 2024', '2024-04-01', '2024-04-30', 'Email', 15000, 'Incrementar contratacion de tarjetas en clientes digitales', 'Finalizada', 1002),
('Prestamo Personal Preaprobado', '2024-04-10', '2024-05-10', 'App', 22000, 'Ofrecer prestamo a clientes con ingresos recurrentes', 'Finalizada', 1003),
('Seguro Proteccion Familiar', '2024-05-01', '2024-05-31', 'Call Center', 12000, 'Vender seguros a clientes con tarjetas activas', 'Activa', 1004),
('Inversion Conservadora Premium', '2024-05-05', '2024-06-15', 'Ejecutivo', 30000, 'Captar saldos altos hacia fondos de inversion', 'Activa', 1005),
('Credito Capital Emprendedor', '2024-05-12', '2024-06-20', 'Agencia', 25000, 'Financiar capital de trabajo a independientes', 'Activa', 1006),
('Cuenta Digital Jóvenes', '2024-05-15', '2024-06-15', 'Redes', 10000, 'Aumentar apertura de cuentas digitales', 'Activa', 1007);
GO

/* CAMPANIA_CLIENTE: mas de 20 registros */
INSERT INTO Campania_cliente
(fecha_envio, canal, estado_contacto, respuesta_cliente, fecha_respuesta, id_campania, id_cliente) VALUES
('2024-04-02', 'Email', 'Contactado', 'Acepta', '2024-04-03', 1001, 1001),
('2024-04-02', 'Email', 'Contactado', 'Rechaza', '2024-04-04', 1001, 1002),
('2024-04-03', 'Email', 'Contactado', 'Acepta', '2024-04-05', 1001, 1003),
('2024-04-03', 'Email', 'No contactado', 'Sin respuesta', '2024-04-10', 1001, 1005),
('2024-04-04', 'Email', 'Contactado', 'Acepta', '2024-04-06', 1001, 1009),
('2024-04-04', 'Email', 'Contactado', 'Rechaza', '2024-04-07', 1001, 1010),
('2024-04-11', 'App', 'Contactado', 'Acepta', '2024-04-12', 1002, 1002),
('2024-04-11', 'App', 'Contactado', 'Acepta', '2024-04-13', 1002, 1004),
('2024-04-12', 'App', 'Contactado', 'Rechaza', '2024-04-13', 1002, 1006),
('2024-04-13', 'App', 'Contactado', 'Acepta', '2024-04-15', 1002, 1011),
('2024-04-14', 'App', 'No contactado', 'Sin respuesta', '2024-04-20', 1002, 1014),
('2024-04-15', 'App', 'Contactado', 'Acepta', '2024-04-16', 1002, 1015),
('2024-05-02', 'Telefono', 'Contactado', 'Acepta', '2024-05-03', 1003, 1001),
('2024-05-02', 'Telefono', 'Contactado', 'Rechaza', '2024-05-03', 1003, 1003),
('2024-05-03', 'Telefono', 'Contactado', 'Acepta', '2024-05-05', 1003, 1005),
('2024-05-03', 'Telefono', 'No contactado', 'Sin respuesta', '2024-05-10', 1003, 1007),
('2024-05-04', 'Telefono', 'Contactado', 'Acepta', '2024-05-06', 1003, 1010),
('2024-05-06', 'Ejecutivo', 'Contactado', 'Acepta', '2024-05-08', 1004, 1002),
('2024-05-06', 'Ejecutivo', 'Contactado', 'Acepta', '2024-05-09', 1004, 1004),
('2024-05-07', 'Ejecutivo', 'Contactado', 'Acepta', '2024-05-11', 1004, 1008),
('2024-05-08', 'Ejecutivo', 'Contactado', 'Rechaza', '2024-05-12', 1004, 1012),
('2024-05-13', 'Agencia', 'Contactado', 'Acepta', '2024-05-14', 1005, 1003),
('2024-05-13', 'Agencia', 'Contactado', 'Acepta', '2024-05-15', 1005, 1006),
('2024-05-14', 'Agencia', 'Contactado', 'Rechaza', '2024-05-15', 1005, 1011),
('2024-05-14', 'Agencia', 'Contactado', 'Acepta', '2024-05-16', 1005, 1014),
('2024-05-16', 'Redes', 'Contactado', 'Acepta', '2024-05-17', 1006, 1001),
('2024-05-16', 'Redes', 'Contactado', 'Acepta', '2024-05-18', 1006, 1007),
('2024-05-17', 'Redes', 'Contactado', 'Rechaza', '2024-05-18', 1006, 1010),
('2024-05-17', 'Redes', 'Contactado', 'Acepta', '2024-05-19', 1006, 1013),
('2024-05-18', 'Redes', 'No contactado', 'Sin respuesta', '2024-05-25', 1006, 1005);
GO

/* CONVERSIONES: 20 registros */
INSERT INTO Conversion
(fecha_conversion, monto, canal_conversion, estado_conversion, id_camp_cliente) VALUES
('2024-04-04', 10000, 'App', 'Confirmada', 1001),
('2024-04-06', 12000, 'Web', 'Confirmada', 1003),
('2024-04-07', 9000, 'Web', 'Confirmada', 1005),
('2024-04-13', 18000, 'App', 'Confirmada', 1007),
('2024-04-14', 30000, 'App', 'Confirmada', 1008),
('2024-04-16', 25000, 'App', 'Confirmada', 1010),
('2024-04-17', 14000, 'App', 'Confirmada', 1012),
('2024-05-04', 5000, 'Telefono', 'Confirmada', 1013),
('2024-05-06', 3000, 'Telefono', 'Confirmada', 1015),
('2024-05-07', 4000, 'Telefono', 'Confirmada', 1017),
('2024-05-09', 20000, 'Ejecutivo', 'Confirmada', 1018),
('2024-05-10', 50000, 'Ejecutivo', 'Confirmada', 1019),
('2024-05-12', 70000, 'Ejecutivo', 'Confirmada', 1020),
('2024-05-15', 35000, 'Agencia', 'Confirmada', 1022),
('2024-05-16', 45000, 'Agencia', 'Confirmada', 1023),
('2024-05-17', 15000, 'Agencia', 'Pendiente', 1025),
('2024-05-18', 2500, 'Redes', 'Confirmada', 1026),
('2024-05-19', 2800, 'Redes', 'Confirmada', 1027),
('2024-05-20', 3200, 'Redes', 'Confirmada', 1029),
('2024-05-26', 1500, 'Redes', 'Pendiente', 1030);
GO

SELECT 'Carga de datos finalizada correctamente' AS mensaje;
GO
