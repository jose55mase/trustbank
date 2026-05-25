# Documento de Requisitos - Módulo de Leads por Excel

## Introducción

Este módulo permite a los administradores del panel administrativo cargar archivos Excel con datos de leads/contactos, mapear automáticamente las columnas del archivo a los campos del sistema, visualizar los registros importados, buscar entre ellos y editar la información de cada lead individualmente. El módulo se integra al panel administrativo existente de la aplicación Flutter y utiliza el backend Spring Boot para el procesamiento y almacenamiento de datos.

## Glosario

- **Módulo_Leads**: Sección del panel administrativo dedicada a la gestión de leads importados desde archivos Excel.
- **Lead**: Registro de un contacto/prospecto con información de nombre, apellido, estado de llamada, país, teléfono, email, campaña, fecha de registro y comentarios.
- **Archivo_Excel**: Archivo en formato .xlsx o .xls que contiene datos de leads organizados en columnas.
- **Motor_Mapeo**: Componente del sistema que analiza las columnas del archivo Excel y las asocia automáticamente a los campos del Lead.
- **Panel_Administrativo**: Interfaz de administración existente en la aplicación Flutter con acceso restringido por roles.
- **Buscador_Leads**: Componente de búsqueda que permite filtrar registros de leads por cualquier campo.
- **API_Backend**: Servicio REST del backend Spring Boot que procesa las solicitudes del módulo de leads.

## Requisitos

### Requisito 1: Carga de Archivo Excel

**Historia de Usuario:** Como administrador, quiero subir un archivo Excel con datos de leads, para poder importar contactos de forma masiva al sistema.

#### Criterios de Aceptación

1. THE Módulo_Leads SHALL proporcionar un botón de carga que permita seleccionar archivos con extensión .xlsx o .xls desde el dispositivo del usuario.
2. WHEN el administrador selecciona un archivo Excel válido, THE Módulo_Leads SHALL enviar el archivo al API_Backend para su procesamiento.
3. WHILE el archivo se está procesando, THE Módulo_Leads SHALL mostrar un indicador de progreso con el estado de la carga.
4. IF el archivo seleccionado no tiene extensión .xlsx o .xls, THEN THE Módulo_Leads SHALL mostrar un mensaje de error indicando que el formato no es compatible.
5. IF el archivo excede el tamaño máximo permitido de 10MB, THEN THE Módulo_Leads SHALL mostrar un mensaje de error indicando el límite de tamaño.

### Requisito 2: Mapeo Automático de Columnas

**Historia de Usuario:** Como administrador, quiero que el sistema detecte automáticamente a qué campo corresponde cada columna del Excel, para no tener que configurar manualmente la correspondencia.

#### Criterios de Aceptación

1. WHEN el API_Backend recibe un archivo Excel, THE Motor_Mapeo SHALL analizar los encabezados de las columnas y asociarlos a los campos del Lead: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña, Fecha_de_Registro y Comentarios.
2. WHEN el Motor_Mapeo no puede determinar la correspondencia de una columna con certeza, THE Módulo_Leads SHALL presentar al administrador una interfaz para asignar manualmente las columnas no reconocidas.
3. THE Motor_Mapeo SHALL utilizar coincidencia por similitud de texto en los encabezados para determinar la correspondencia entre columnas y campos del Lead.
4. WHEN el mapeo automático se completa, THE Módulo_Leads SHALL mostrar una vista previa con la correspondencia detectada entre columnas del Excel y campos del sistema antes de confirmar la importación.
5. IF el archivo Excel no contiene encabezados reconocibles, THEN THE Módulo_Leads SHALL solicitar al administrador que asigne manualmente cada columna a un campo del Lead.

### Requisito 3: Importación y Almacenamiento de Leads

**Historia de Usuario:** Como administrador, quiero que los datos del Excel se almacenen correctamente en el sistema, para poder gestionarlos posteriormente.

#### Criterios de Aceptación

1. WHEN el administrador confirma el mapeo de columnas, THE API_Backend SHALL procesar cada fila del archivo Excel y crear un registro de Lead por cada fila válida.
2. THE API_Backend SHALL almacenar cada Lead con los campos: Nombre (texto), Apellido (texto), Last_Call_Status (texto), País (texto), Teléfono (texto), Email (texto), Campaña (texto), Fecha_de_Registro (fecha) y Comentarios (texto).
3. IF una fila del Excel contiene datos inválidos o incompletos, THEN THE API_Backend SHALL registrar el error y continuar procesando las filas restantes.
4. WHEN la importación finaliza, THE Módulo_Leads SHALL mostrar un resumen indicando la cantidad de registros importados exitosamente y la cantidad de registros con errores.
5. THE API_Backend SHALL asociar cada importación con la fecha de carga y el administrador que realizó la operación.

### Requisito 4: Listado de Leads

**Historia de Usuario:** Como administrador, quiero ver todos los leads importados en una lista organizada, para poder revisar la información de los contactos.

#### Criterios de Aceptación

1. THE Módulo_Leads SHALL mostrar una tabla con todos los leads importados, incluyendo las columnas: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email y Campaña.
2. THE Módulo_Leads SHALL implementar paginación con un máximo de 20 registros por página.
3. WHEN el administrador navega entre páginas, THE Módulo_Leads SHALL cargar los registros correspondientes desde el API_Backend.
4. THE Módulo_Leads SHALL permitir ordenar la tabla por cualquiera de las columnas visibles de forma ascendente o descendente.

### Requisito 5: Búsqueda de Leads

**Historia de Usuario:** Como administrador, quiero buscar leads por cualquier campo, para poder encontrar rápidamente un contacto específico.

#### Criterios de Aceptación

1. THE Buscador_Leads SHALL proporcionar un campo de texto para ingresar términos de búsqueda.
2. WHEN el administrador ingresa un término de búsqueda, THE Buscador_Leads SHALL filtrar los registros que coincidan en cualquiera de los campos: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña o Comentarios.
3. THE Buscador_Leads SHALL ejecutar la búsqueda después de que el administrador deje de escribir durante 300 milisegundos (debounce).
4. WHEN no se encuentran resultados para el término de búsqueda, THE Buscador_Leads SHALL mostrar un mensaje indicando que no hay coincidencias.
5. THE API_Backend SHALL ejecutar la búsqueda en la base de datos y retornar los resultados paginados.

### Requisito 6: Visualización de Detalle del Lead

**Historia de Usuario:** Como administrador, quiero ver todos los datos de un lead al hacer clic en él, para poder revisar su información completa.

#### Criterios de Aceptación

1. WHEN el administrador hace clic en un registro de la tabla, THE Módulo_Leads SHALL mostrar una vista de detalle con todos los campos del Lead: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña, Fecha_de_Registro y Comentarios.
2. THE Módulo_Leads SHALL presentar la vista de detalle en un diálogo modal o pantalla dedicada con formato legible.
3. THE Módulo_Leads SHALL incluir un botón para editar el lead desde la vista de detalle.

### Requisito 7: Edición de Leads

**Historia de Usuario:** Como administrador, quiero editar los datos de un lead, para poder corregir o actualizar su información.

#### Criterios de Aceptación

1. WHEN el administrador activa el modo de edición de un lead, THE Módulo_Leads SHALL mostrar un formulario con todos los campos editables: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña, Fecha_de_Registro y Comentarios.
2. THE Módulo_Leads SHALL validar que los campos Email y Teléfono contengan formatos válidos antes de enviar la actualización.
3. WHEN el administrador guarda los cambios, THE API_Backend SHALL actualizar el registro del Lead en la base de datos.
4. IF la actualización es exitosa, THEN THE Módulo_Leads SHALL mostrar un mensaje de confirmación y actualizar la vista con los datos modificados.
5. IF la actualización falla, THEN THE Módulo_Leads SHALL mostrar un mensaje de error descriptivo sin perder los datos ingresados por el administrador.
6. THE Módulo_Leads SHALL permitir cancelar la edición y volver a la vista de detalle sin guardar cambios.

### Requisito 8: Control de Acceso

**Historia de Usuario:** Como dueño del producto, quiero que solo los administradores autorizados puedan acceder al módulo de leads, para proteger la información de los contactos.

#### Criterios de Aceptación

1. THE Panel_Administrativo SHALL restringir el acceso al Módulo_Leads únicamente a usuarios con permisos de administrador.
2. IF un usuario sin permisos intenta acceder al Módulo_Leads, THEN THE Panel_Administrativo SHALL mostrar un mensaje de acceso denegado.
3. THE API_Backend SHALL validar los permisos del usuario en cada solicitud relacionada con el módulo de leads.
