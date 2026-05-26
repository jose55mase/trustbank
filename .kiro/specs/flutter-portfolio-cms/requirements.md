# Documento de Requisitos

## Introducción

Este documento define los requisitos para un portafolio web desarrollado en Flutter con un sistema de gestión de contenido (CMS) integrado. La aplicación consta de dos áreas principales: una página pública para visitantes que muestra proyectos de software mediante un carrusel interactivo y un catálogo, y un panel administrativo que permite al propietario modificar todo el contenido visible (textos, imágenes, títulos) sin necesidad de intervención técnica. La paleta de colores utiliza tonos pastel suavizados de azul, negro y naranja.

## Glosario

- **Aplicación**: La aplicación web Flutter que comprende la Página_Pública y el Panel_Administrativo
- **Página_Pública**: La interfaz visible para visitantes no autenticados que muestra el portafolio
- **Panel_Administrativo**: La interfaz protegida por autenticación que permite gestionar el contenido
- **Carrusel**: Componente interactivo de la Página_Pública que muestra proyectos de software con animaciones de texto e imágenes
- **Catálogo**: Sección de la Página_Pública que presenta una colección de proyectos realizados
- **Menú_Navegación**: Componente de navegación principal visible para visitantes en la Página_Pública
- **Proyecto**: Entidad del catálogo que contiene título, descripción, imágenes y metadatos asociados
- **Propietario**: Usuario autenticado con permisos completos para gestionar todo el contenido de la Aplicación
- **Contenido_Editable**: Cualquier texto, imagen o título que el Propietario puede modificar desde el Panel_Administrativo
- **Paleta_Colores**: Conjunto de colores definidos en tonos pastel suavizados de azul, negro y naranja

## Requisitos

### Requisito 1: Navegación para Visitantes

**Historia de Usuario:** Como visitante, quiero un menú de navegación claro y accesible, para poder explorar las diferentes secciones del portafolio fácilmente.

#### Criterios de Aceptación

1. THE Página_Pública SHALL mostrar un Menú_Navegación en posición fija visible en todo momento durante el desplazamiento, con enlaces a todas las secciones disponibles de la Página_Pública
2. WHEN un visitante selecciona un enlace del Menú_Navegación, THE Aplicación SHALL desplazar la vista hacia la sección correspondiente con una animación de desplazamiento de entre 300 y 500 milisegundos de duración
3. WHILE la pantalla tiene un ancho menor a 768 píxeles, THE Menú_Navegación SHALL colapsar en un menú tipo hamburguesa mostrando únicamente un icono de activación
4. WHEN un visitante selecciona el icono del menú hamburguesa, THE Menú_Navegación SHALL expandir un panel con todos los enlaces de navegación, y WHEN el visitante selecciona el icono nuevamente o selecciona un enlace, THE Menú_Navegación SHALL cerrar el panel
5. THE Menú_Navegación SHALL aplicar los colores de la Paleta_Colores en tonos pastel suavizados

### Requisito 2: Carrusel Interactivo de Software

**Historia de Usuario:** Como visitante, quiero ver un carrusel interactivo con proyectos de software destacados, para conocer rápidamente los trabajos más relevantes del portafolio.

#### Criterios de Aceptación

1. THE Página_Pública SHALL mostrar un Carrusel con los Proyectos marcados como destacados en el Panel_Administrativo, mostrando un mínimo de 1 y un máximo de 10 Proyectos
2. WHEN un visitante interactúa con el Carrusel mediante gestos de deslizamiento o botones de navegación, THE Carrusel SHALL transicionar al siguiente o anterior Proyecto con una animación que se complete en un máximo de 500 milisegundos
3. THE Carrusel SHALL mostrar para cada Proyecto un título de máximo 60 caracteres, un texto descriptivo de máximo 200 caracteres y al menos una imagen con animaciones de entrada que se completen en un máximo de 400 milisegundos
4. WHEN el Carrusel permanece sin interacción del visitante durante 5 segundos, THE Carrusel SHALL avanzar automáticamente al siguiente Proyecto, volviendo al primer Proyecto después del último de forma cíclica
5. IF el Carrusel no puede cargar una imagen de un Proyecto, THEN THE Carrusel SHALL mostrar una imagen de respaldo con el título del Proyecto
6. WHEN un visitante interactúa con el Carrusel mediante gestos de deslizamiento o botones de navegación, THE Carrusel SHALL reiniciar el temporizador de avance automático de 5 segundos
7. THE Carrusel SHALL mostrar un indicador de posición que señale el Proyecto actualmente visible y el total de Proyectos disponibles

### Requisito 3: Catálogo de Proyectos Realizados

**Historia de Usuario:** Como visitante, quiero explorar un catálogo completo de proyectos realizados, para evaluar la experiencia y capacidades del portafolio.

#### Criterios de Aceptación

1. THE Página_Pública SHALL mostrar un Catálogo con todos los Proyectos registrados en el sistema
2. THE Catálogo SHALL presentar cada Proyecto con su título, una descripción truncada a un máximo de 150 caracteres e imagen principal
3. WHEN un visitante selecciona un Proyecto del Catálogo, THE Aplicación SHALL mostrar una vista detallada con el título, la descripción completa, todas las imágenes asociadas y los metadatos del Proyecto
4. WHILE la pantalla tiene un ancho menor a 768 píxeles, THE Catálogo SHALL reorganizar los Proyectos en una columna única
5. WHILE la pantalla tiene un ancho igual o mayor a 768 píxeles, THE Catálogo SHALL organizar los Proyectos en una cuadrícula de dos o más columnas
6. IF no existen Proyectos registrados en el sistema, THEN THE Catálogo SHALL mostrar un mensaje indicando que no hay proyectos disponibles
7. IF la imagen principal de un Proyecto no puede cargarse en el Catálogo, THEN THE Catálogo SHALL mostrar una imagen de respaldo con el título del Proyecto

### Requisito 4: Autenticación del Panel Administrativo

**Historia de Usuario:** Como propietario, quiero acceder al panel administrativo de forma segura, para proteger la gestión del contenido de accesos no autorizados.

#### Criterios de Aceptación

1. WHEN el Propietario ingresa un nombre de usuario y contraseña válidos en el formulario de inicio de sesión, THE Panel_Administrativo SHALL conceder acceso completo a las funciones de gestión
2. IF el Propietario ingresa credenciales inválidas, THEN THE Panel_Administrativo SHALL mostrar un mensaje de error indicando que las credenciales son incorrectas sin revelar cuál campo específico falló
3. WHILE el Propietario no está autenticado, THE Aplicación SHALL redirigir cualquier intento de acceso a rutas del Panel_Administrativo hacia el formulario de inicio de sesión
4. WHEN la sesión del Propietario expira después de 60 minutos de inactividad, THE Panel_Administrativo SHALL redirigir al formulario de inicio de sesión preservando la URL de la ruta donde se encontraba
5. IF el Propietario acumula 5 intentos fallidos de inicio de sesión consecutivos, THEN THE Panel_Administrativo SHALL bloquear temporalmente el acceso a la cuenta durante 15 minutos y mostrar un mensaje indicando el tiempo de espera restante

### Requisito 5: Gestión de Proyectos del Catálogo

**Historia de Usuario:** Como propietario, quiero agregar, editar y eliminar proyectos del catálogo, para mantener actualizado mi portafolio con los trabajos más recientes.

#### Criterios de Aceptación

1. WHEN el Propietario selecciona la opción de agregar un Proyecto, THE Panel_Administrativo SHALL presentar un formulario con los campos obligatorios título (máximo 100 caracteres), descripción (máximo 500 caracteres) e imagen principal, y los campos opcionales imágenes adicionales (máximo 5 imágenes por Proyecto), enlace externo y tecnologías utilizadas
2. WHEN el Propietario envía un formulario de Proyecto con todos los campos obligatorios completos y las imágenes en formato PNG, JPG o WebP con tamaño no superior a 5 MB cada una, THE Panel_Administrativo SHALL guardar el Proyecto y mostrar el Proyecto en el Catálogo de la Página_Pública sin requerir recarga manual
3. WHEN el Propietario selecciona editar un Proyecto existente, THE Panel_Administrativo SHALL cargar los datos actuales del Proyecto en el formulario de edición con todos los campos prellenados con los valores guardados
4. WHEN el Propietario selecciona eliminar un Proyecto, THE Panel_Administrativo SHALL presentar un diálogo de confirmación indicando el título del Proyecto, y WHEN el Propietario confirma la eliminación, THE Panel_Administrativo SHALL remover el Proyecto del Catálogo
5. IF el Propietario envía un formulario con campos obligatorios vacíos (título, descripción o imagen principal), THEN THE Panel_Administrativo SHALL señalar cada campo faltante con un mensaje de validación junto al campo correspondiente sin borrar los datos ya ingresados en otros campos
6. IF el guardado o eliminación de un Proyecto falla por error de conexión o del servidor, THEN THE Panel_Administrativo SHALL mostrar un mensaje de error indicando que la operación no se completó y SHALL preservar los datos ingresados en el formulario para permitir reintento

### Requisito 6: Edición de Contenido de la Página Principal

**Historia de Usuario:** Como propietario, quiero modificar todos los textos, imágenes y títulos de la página principal, para personalizar completamente la presentación del portafolio sin asistencia técnica.

#### Criterios de Aceptación

1. THE Panel_Administrativo SHALL listar todos los elementos de Contenido_Editable de la Página_Pública organizados por sección
2. WHEN el Propietario modifica un texto o título de la Página_Pública, THE Panel_Administrativo SHALL guardar el cambio y reflejarlo en la Página_Pública en un máximo de 5 segundos sin requerir recarga manual
3. WHEN el Propietario sube una nueva imagen para reemplazar una existente, THE Panel_Administrativo SHALL validar que el formato sea PNG, JPG o WebP y que el tamaño no exceda 5 MB
4. IF el Propietario sube una imagen con formato no soportado o tamaño superior a 5 MB, THEN THE Panel_Administrativo SHALL rechazar la carga y mostrar un mensaje indicando las restricciones de formato y tamaño permitidos
5. WHEN el Propietario modifica el contenido del Carrusel, THE Panel_Administrativo SHALL permitir editar el título (máximo 100 caracteres), texto descriptivo (máximo 300 caracteres) e imagen de cada elemento del Carrusel
6. IF el Propietario intenta guardar un texto o título vacío en un campo obligatorio de Contenido_Editable, THEN THE Panel_Administrativo SHALL rechazar el cambio y señalar el campo con un mensaje de validación indicando que el contenido es requerido
7. IF el Panel_Administrativo no puede completar la operación de guardado de un cambio de contenido, THEN THE Panel_Administrativo SHALL mostrar un mensaje de error indicando que el cambio no fue guardado y preservar el contenido editado en el formulario para permitir reintento

### Requisito 7: Paleta de Colores y Tema Visual

**Historia de Usuario:** Como propietario, quiero que la aplicación utilice una paleta de colores consistente en tonos pastel suavizados de azul, negro y naranja, para transmitir una identidad visual profesional y coherente.

#### Criterios de Aceptación

1. THE Aplicación SHALL utilizar como color primario un azul pastel suavizado con valores HSL dentro del rango H: 205-215, S: 35%-45%, L: 70%-80%
2. THE Aplicación SHALL utilizar como color secundario un naranja pastel suavizado con valores HSL dentro del rango H: 20-30, S: 40%-50%, L: 70%-80%
3. THE Aplicación SHALL utilizar como color de acento un negro suavizado con valores HSL dentro del rango H: 0-360, S: 0%-5%, L: 15%-25%
4. THE Aplicación SHALL aplicar la Paleta_Colores en todos los textos, fondos, botones y elementos interactivos de la Página_Pública y el Panel_Administrativo, utilizando exclusivamente colores derivados de los tres roles definidos (primario, secundario y acento)
5. THE Aplicación SHALL mantener un contraste mínimo de 4.5:1 entre texto de tamaño estándar y su fondo, y un contraste mínimo de 3:1 entre texto de tamaño grande (18pt o superior) y su fondo, conforme al nivel AA de WCAG 2.1
6. IF la combinación de un color de la Paleta_Colores con un fondo no alcanza el contraste mínimo requerido, THEN THE Aplicación SHALL utilizar el color de acento como alternativa para garantizar la legibilidad

### Requisito 8: Diseño Responsivo

**Historia de Usuario:** Como visitante, quiero que la página se adapte correctamente a diferentes tamaños de pantalla, para poder navegar cómodamente desde cualquier dispositivo.

#### Criterios de Aceptación

1. WHILE la pantalla tiene un ancho menor a 768 píxeles, THE Página_Pública SHALL adaptar todos los componentes a un diseño de columna única donde los elementos interactivos tengan un área táctil mínima de 44x44 píxeles
2. WHILE la pantalla tiene un ancho entre 768 y 1024 píxeles, THE Página_Pública SHALL adaptar los componentes a un diseño de tableta con márgenes laterales de al menos 24 píxeles a cada lado y un máximo del 5% del ancho de pantalla
3. WHILE la pantalla tiene un ancho mayor a 1024 píxeles, THE Página_Pública SHALL mostrar los componentes en un diseño de escritorio con ancho máximo de contenido de 1200 píxeles centrado horizontalmente
4. THE Aplicación SHALL renderizar sin diferencias funcionales ni de disposición de elementos en los navegadores Chrome, Firefox, Safari y Edge en sus dos versiones más recientes, verificando que todos los componentes sean visibles, interactivos y mantengan la estructura de diseño definida en los criterios 1 a 3
5. WHILE la pantalla tiene cualquier ancho soportado, THE Página_Pública SHALL presentar todo el contenido sin requerir desplazamiento horizontal y las imágenes SHALL escalar manteniendo su proporción de aspecto original sin desbordar su contenedor
