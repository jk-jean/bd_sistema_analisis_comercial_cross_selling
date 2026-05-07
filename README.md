📊 CASO PROPUESTO
“Sistema de Análisis Comercial y Cross-Selling Bancario” 🏦
1. Contexto del negocio

El banco DataBank Perú es una entidad financiera que ofrece productos como cuentas de ahorro, tarjetas de crédito, préstamos personales, seguros, depósitos a plazo y créditos vehiculares.

Actualmente, el banco realiza campañas comerciales de forma masiva, enviando ofertas a muchos clientes sin considerar adecuadamente su perfil, ingresos, comportamiento transaccional, productos contratados o nivel de actividad.

Esto genera algunos problemas:

Baja tasa de conversión.
Clientes reciben ofertas poco relevantes.
No se aprovechan oportunidades de venta cruzada.
Las áreas comerciales no tienen una visión integral del cliente.
No se mide correctamente la efectividad de las campañas.

Por ello, el banco ha decidido desarrollar un Sistema de Análisis Comercial y Cross-Selling Bancario, que permita centralizar la información de clientes, productos, campañas, interacciones y conversiones para mejorar la toma de decisiones comerciales.

2. Objetivo del sistema

Diseñar una base de datos que permita:

Registrar información completa de los clientes.

Gestionar los productos financieros contratados por cada cliente.

Analizar el comportamiento transaccional de los clientes.

Registrar campañas comerciales dirigidas a clientes.

Medir la respuesta de los clientes ante las campañas.

Registrar conversiones comerciales.

Identificar oportunidades de cross-selling.

Generar indicadores para evaluar la efectividad comercial del banco.

3. Alcance funcional

El sistema debe contemplar las siguientes áreas:

👤 3.1 Gestión de Clientes

El banco registra información de sus clientes personas naturales.

Cada cliente debe tener:

DNI
Nombres
Apellidos
Fecha de nacimiento
Edad
Género
Distrito
Provincia
Departamento
Ingreso mensual
Situación laboral
Fecha de alta como cliente
Segmento bancario

Los segmentos pueden ser:

Clásico
Preferente
Premium
Empresarial

Un cliente puede tener múltiples cuentas, varios productos financieros y puede participar en diferentes campañas comerciales.

🏦 3.2 Gestión de Cuentas Bancarias

El sistema debe registrar las cuentas que tiene cada cliente.

Cada cuenta debe tener:

Número de cuenta
Cliente asociado
Tipo de cuenta
Moneda
Saldo actual
Fecha de apertura
Estado de cuenta

Tipos de cuenta:

Cuenta de ahorros
Cuenta corriente
Cuenta sueldo

Estados:

Activa
Inactiva
Bloqueada
Cancelada

💳 3.3 Gestión de Productos Financieros

El banco ofrece distintos productos financieros.

Los productos pueden ser:

Tarjeta de crédito
Préstamo personal
Seguro de vida
Seguro vehicular
Depósito a plazo
Crédito vehicular
Crédito hipotecario
Cuenta sueldo

Cada producto debe tener:

Código de producto
Nombre del producto
Tipo de producto
Tasa de interés o comisión
Monto mínimo
Monto máximo
Estado del producto
Fecha de creación

📌 3.4 Productos Contratados por Cliente

El sistema debe registrar qué productos tiene contratado cada cliente.

Cada producto contratado debe tener:

Cliente
Producto financiero
Fecha de contratación
Monto aprobado
Monto utilizado
Saldo actual
Canal de contratación
Estado del producto contratado

Canales posibles:

Agencia
App móvil
Web
Call center
Ejecutivo comercial

Estados:

Activo
Cancelado
Bloqueado
Vencido

Esto permitirá saber qué productos ya tiene un cliente y qué productos podrían ofrecérsele.

🔁 3.5 Comportamiento Transaccional

El sistema debe registrar las transacciones realizadas por los clientes.

Cada transacción debe tener:

Cliente
Cuenta asociada
Fecha de transacción
Tipo de transacción
Monto
Canal
Categoría
Estado de la transacción

Tipos de transacción:

Depósito
Retiro
Transferencia
Pago de servicio
Consumo con tarjeta
Pago de crédito

Canales:

App móvil
Web
Agencia
ATM
POS

Categorías:

Alimentos
Transporte
Educación
Salud
Entretenimiento
Servicios
Otros

Esto servirá para identificar clientes activos, clientes digitales, clientes con alto consumo y clientes con potencial comercial.

📣 3.6 Gestión de Campañas Comerciales

El banco lanza campañas para ofrecer productos financieros a determinados clientes.

Cada campaña debe tener:

Código de campaña
Nombre de campaña
Producto ofrecido
Fecha de inicio
Fecha de fin
Canal principal
Presupuesto
Objetivo de campaña
Estado de campaña

Ejemplos de campañas:

Campaña Tarjeta de Crédito Premium
Campaña Préstamo Personal Preaprobado
Campaña Seguro de Vida
Campaña Depósito a Plazo
Campaña Crédito Vehicular

Estados:

Planificada
Activa
Finalizada
Pausada
Cancelada

📬 3.7 Clientes Impactados por Campaña

El sistema debe registrar qué clientes fueron seleccionados para cada campaña.

Cada registro debe tener:

Campaña
Cliente
Fecha de envío
Canal utilizado
Estado del contacto
Respuesta del cliente
Fecha de respuesta

Estados del contacto:

Enviado
Abierto
Clic
Contactado
No contactado

Respuestas del cliente:

Interesado
No interesado
Pendiente
No responde

Esto permitirá medir cuántos clientes fueron impactados y cuántos mostraron interés.

✅ 3.8 Conversión Comercial

Cuando un cliente acepta una oferta y contrata el producto, el sistema debe registrar una conversión.

Cada conversión debe tener:

Cliente
Campaña
Producto contratado
Fecha de conversión
Monto contratado
Canal de conversión
Ejecutivo responsable
Estado de conversión

Estados:

Aprobado
Rechazado
En evaluación
Desembolsado
Cancelado

Esto permitirá calcular la tasa de conversión y el monto colocado por campaña.

👨‍💼 3.9 Gestión de Ejecutivos Comerciales

El sistema debe registrar a los ejecutivos que participan en campañas o conversiones.

Cada ejecutivo debe tener:

Código de ejecutivo
Nombres
Apellidos
Sucursal
Cargo
Fecha de ingreso
Estado

Un ejecutivo puede gestionar varias conversiones comerciales.

🏢 3.10 Gestión de Sucursales

El banco puede tener diferentes sucursales.

Cada sucursal debe tener:

Código de sucursal
Nombre de sucursal
Distrito
Provincia
Departamento
Dirección
Estado

Una sucursal puede tener varios ejecutivos asociados.

4. Reglas de negocio clave

Un cliente puede tener una o varias cuentas bancarias.

Una cuenta pertenece a un solo cliente.

Un cliente puede tener varios productos financieros contratados.

Un producto financiero puede estar contratado por muchos clientes.

Una campaña comercial ofrece un producto financiero principal.

Una campaña puede impactar a muchos clientes.

Un cliente puede ser impactado por varias campañas.

Un cliente puede convertir una o más campañas.

No se debe ofrecer un producto que el cliente ya tiene activo.

Una conversión debe estar asociada a una campaña y a un cliente.

Una conversión puede ser gestionada por un ejecutivo comercial.

Una campaña debe tener una fecha de inicio y una fecha de fin.

El monto contratado en una conversión no debe superar el monto máximo permitido del producto.

Los clientes con mayores ingresos, mayor actividad transaccional y menor cantidad de productos contratados pueden ser considerados clientes con alto potencial de cross-selling.
