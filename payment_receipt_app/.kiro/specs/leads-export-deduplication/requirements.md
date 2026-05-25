# Documento de Requisitos - Exportación y Deduplicación de Leads

## Introducción

Este documento define los requisitos para dos nuevas funcionalidades del módulo de leads existente en el panel administrativo: (1) la exportación de todos los leads a un archivo Excel (.xlsx) para que el administrador tenga una copia local de los datos, y (2) la deduplicación durante la importación de nuevos archivos Excel, evitando la inserción de registros que ya existen en la base de datos basándose en coincidencia de email o teléfono.

## Glosario

- **Módulo_Leads**: Sección del panel administrativo dedicada a la gestión de leads importados desde archivos Excel.
- **Lead**: Registro de un contacto/prospecto con información de nombre, apellido, estado de llamada, país, teléfono, email, campaña, fecha de registro y comentarios.
- **API_Backend**: Servicio REST del backend Spring Boot que procesa las solicitudes del módulo de leads.
- **Motor_Deduplicación**: Componente del backend que compara los datos entrantes con los leads existentes para identificar duplicados.
- **Archivo_Exportado**: Archivo Excel (.xlsx) generado por el sistema que contiene todos los leads almacenados en la base de datos.
- **Resumen_Importación**: Respuesta del sistema al finalizar una importación que indica la cantidad de registros importados, omitidos por duplicado y con errores.
- **Lead_Duplicado**: Fila del archivo Excel de importación cuyo email o teléfono coincide exactamente con un lead ya existente en la base de datos.

## Requisitos

### Requisito 1: Exportación de Leads a Excel

**Historia de Usuario:** Como administrador, quiero descargar todos los leads existentes en un archivo Excel (.xlsx), para poder tener una copia local de los datos y trabajar con ellos fuera del sistema.

#### Criterios de Aceptación

1. THE Módulo_Leads SHALL proporcionar un botón de exportación visible en la pantalla de listado de leads que permita iniciar la descarga del archivo Excel.
2. WHEN el administrador presiona el botón de exportación, THE API_Backend SHALL generar un archivo Excel (.xlsx) que contenga todos los leads almacenados en la base de datos dentro de un tiempo máximo de 60 segundos.
3. THE Archivo_Exportado SHALL incluir una fila de encabezados con los nombres de los campos: Nombre, Apellido, Last Call Status, País, Teléfono, Email, Campaña, Fecha de Registro y Comentarios.
4. THE Archivo_Exportado SHALL contener una fila por cada lead existente en la base de datos, con los valores correspondientes a cada campo del encabezado.
5. WHILE el archivo se está generando y descargando, THE Módulo_Leads SHALL mostrar un indicador visual de carga al administrador y deshabilitar el botón de exportación para prevenir solicitudes duplicadas.
6. WHEN la generación del archivo finaliza exitosamente, THE Módulo_Leads SHALL iniciar la descarga automática del archivo en el navegador o dispositivo del administrador y rehabilitar el botón de exportación.
7. IF ocurre un error durante la generación del archivo, THEN THE Módulo_Leads SHALL mostrar un mensaje de error al administrador que indique la causa general del fallo, rehabilitar el botón de exportación y preservar la navegación actual sin redirigir ni recargar la página.
8. THE Archivo_Exportado SHALL utilizar el formato de nombre "leads_export_YYYYMMDD_HHmmss.xlsx" donde la fecha y hora corresponden al momento de la generación en la zona horaria del servidor.
9. IF el tiempo de generación del archivo excede 60 segundos, THEN THE API_Backend SHALL cancelar la operación y THE Módulo_Leads SHALL mostrar un mensaje de error indicando que la exportación excedió el tiempo límite.

### Requisito 2: Deduplicación durante la Importación

**Historia de Usuario:** Como administrador, quiero que al importar un nuevo archivo Excel, el sistema detecte y omita los registros que ya existen en la base de datos, para evitar leads duplicados.

#### Criterios de Aceptación

1. WHEN el administrador confirma la importación de un archivo Excel, THE Motor_Deduplicación SHALL comparar cada fila del archivo con los leads existentes en la base de datos antes de insertarla.
2. THE Motor_Deduplicación SHALL considerar una fila como duplicada si el email de la fila coincide exactamente (sin distinguir mayúsculas/minúsculas y eliminando espacios en blanco al inicio y al final) con el email de un lead existente en la base de datos.
3. THE Motor_Deduplicación SHALL considerar una fila como duplicada si el teléfono de la fila, tras eliminar espacios, guiones y paréntesis, coincide exactamente con el teléfono almacenado de un lead existente (también normalizado de la misma forma) en la base de datos.
4. IF una fila es identificada como Lead_Duplicado, THEN THE API_Backend SHALL omitir la inserción de esa fila y continuar procesando las filas restantes del archivo.
5. WHEN la importación finaliza, THE Resumen_Importación SHALL indicar la cantidad total de filas procesadas, la cantidad de registros importados exitosamente, la cantidad de registros omitidos por duplicado y la cantidad de registros con errores.
6. WHEN la importación finaliza, THE Módulo_Leads SHALL mostrar el Resumen_Importación al administrador en la pantalla de resultados de importación, presentando los registros omitidos por duplicado y los registros con errores en secciones o contadores separados con etiquetas distintas.
7. IF una fila tiene tanto email vacío como teléfono vacío, THEN THE Motor_Deduplicación SHALL permitir la importación de esa fila sin verificación de duplicados.
8. THE Motor_Deduplicación SHALL evaluar la deduplicación utilizando condición OR: una fila es duplicada si coincide el email O si coincide el teléfono con un lead existente.
9. IF el archivo Excel contiene filas duplicadas entre sí (mismo email o mismo teléfono entre dos o más filas del archivo), THEN THE Motor_Deduplicación SHALL importar únicamente la primera ocurrencia y omitir las filas subsiguientes como duplicadas.
10. IF una fila tiene email vacío y teléfono con valor, THEN THE Motor_Deduplicación SHALL evaluar la deduplicación únicamente por teléfono; IF una fila tiene teléfono vacío y email con valor, THEN THE Motor_Deduplicación SHALL evaluar la deduplicación únicamente por email.

### Requisito 3: Endpoint de Exportación en el Backend

**Historia de Usuario:** Como desarrollador del frontend, quiero un endpoint REST que genere y retorne el archivo Excel con los leads, para poder integrarlo con la interfaz de descarga.

#### Criterios de Aceptación

1. THE API_Backend SHALL exponer un endpoint GET en la ruta "/api/leads/export" que retorne el archivo Excel con todos los leads ordenados por Fecha_de_Registro de forma descendente (más recientes primero).
2. WHEN el endpoint recibe una solicitud autenticada con rol de administrador, THE API_Backend SHALL generar el archivo Excel en memoria en un tiempo máximo de 30 segundos y retornarlo con Content-Type "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet".
3. THE API_Backend SHALL incluir el header Content-Disposition con el valor "attachment; filename=leads_export_YYYYMMDD_HHmmss.xlsx" en la respuesta.
4. IF no existen leads en la base de datos, THEN THE API_Backend SHALL retornar un archivo Excel que contenga únicamente la fila de encabezados.
5. THE API_Backend SHALL requerir autenticación con rol de administrador para acceder al endpoint de exportación.
6. IF un usuario no autenticado o sin rol de administrador realiza una solicitud al endpoint de exportación, THEN THE API_Backend SHALL retornar un código HTTP 401 si no está autenticado o HTTP 403 si no tiene rol de administrador, sin generar el archivo.
7. IF ocurre un error interno durante la generación del archivo, THEN THE API_Backend SHALL retornar un código HTTP 500 con un cuerpo de respuesta que incluya un mensaje de error indicando la causa general de la falla.
8. IF la generación del archivo excede los 30 segundos, THEN THE API_Backend SHALL cancelar la operación y retornar un código HTTP 504 con un mensaje de error indicando timeout.

### Requisito 4: Respuesta Extendida de Importación con Deduplicación

**Historia de Usuario:** Como administrador, quiero que el resumen de importación me indique cuántos registros fueron omitidos por ser duplicados, para tener visibilidad completa del resultado de la operación.

#### Criterios de Aceptación

1. WHEN la importación con deduplicación finaliza, THE API_Backend SHALL retornar un objeto de respuesta JSON que incluya los campos: totalRows (entero, total de filas procesadas), successCount (entero, importados exitosamente), duplicateCount (entero, omitidos por duplicado) y errorCount (entero, filas con errores).
2. WHEN la importación finaliza, THE Módulo_Leads SHALL mostrar el resumen de importación con tres contadores separados y etiquetados: "Importados exitosamente" (successCount), "Duplicados omitidos" (duplicateCount) y "Errores" (errorCount).
3. THE API_Backend SHALL garantizar que la suma de successCount + duplicateCount + errorCount sea igual a totalRows para cada operación de importación.
4. WHEN se registra la importación en el historial, THE API_Backend SHALL almacenar el campo duplicateCount en la entidad LeadImportEntity junto con totalRows, successCount y errorCount.
