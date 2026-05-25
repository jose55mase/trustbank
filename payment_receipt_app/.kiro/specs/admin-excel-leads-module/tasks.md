# Plan de Implementación: Módulo de Leads por Excel

## Resumen

Este plan implementa el módulo completo de gestión de leads importados desde archivos Excel. Se divide en tareas incrementales que cubren: configuración de dependencias, modelos de datos y entidades (backend), servicios de parsing y mapeo, controlador REST, modelos y servicios Flutter, BLoC para gestión de estado, y pantallas de UI. Cada tarea construye sobre las anteriores para lograr un flujo funcional de extremo a extremo.

## Tareas

- [x] 1. Configurar dependencias y estructura base del backend
  - [x] 1.1 Agregar dependencias Apache POI y jqwik al pom.xml
    - Agregar `poi-ooxml:4.1.2` para parsing de archivos Excel
    - Agregar `jqwik:1.3.10` con scope test para property-based testing
    - Verificar que el proyecto compila correctamente con las nuevas dependencias
    - _Requisitos: 1.2, 2.1_

  - [x] 1.2 Crear entidades JPA LeadEntity y LeadImportEntity
    - Crear `LeadEntity.java` en `models/entity/` con campos: id, nombre, apellido, lastCallStatus, pais, telefono, email, campana, fechaRegistro, comentarios, importId, createdAt, updatedAt
    - Crear `LeadImportEntity.java` en `models/entity/` con campos: id, fileName, adminId, totalRows, successCount, errorCount, status, createdAt
    - Incluir anotaciones JPA (@Entity, @Table, @Column, @Temporal) y serialVersionUID
    - Generar getters, setters y constructores
    - _Requisitos: 3.2, 3.5_

  - [x] 1.3 Crear repositorio ILeadDao e ILeadImportDao
    - Crear `ILeadDao.java` en `models/dao/` extendiendo JpaRepository con métodos: findAll(Pageable), searchByTerm(String, Pageable), findByImportId(Long)
    - Crear `ILeadImportDao.java` en `models/dao/` extendiendo JpaRepository
    - Implementar la query @Query para búsqueda multi-campo con LIKE
    - _Requisitos: 4.2, 5.2, 5.5_

- [x] 2. Implementar servicios de parsing y mapeo en el backend
  - [x] 2.1 Implementar ColumnMappingEngine
    - Crear `ColumnMappingEngine.java` en `models/services/`
    - Implementar mapa de sinónimos FIELD_SYNONYMS para cada campo del Lead (nombre, apellido, lastCallStatus, pais, telefono, email, campana, fechaRegistro, comentarios)
    - Implementar método `calculateSimilarity(String, String)` usando distancia de Levenshtein normalizada
    - Implementar método `mapColumns(List<String> headers)` que retorna MappingResult con el mapeo columna→campo
    - Umbral de similitud: 0.6 para considerar un match válido
    - _Requisitos: 2.1, 2.3_

  - [x] 2.2 Escribir test de propiedad para mapeo de columnas
    - **Propiedad 2: Mapeo de columnas por similitud de texto**
    - Generar variaciones de encabezados (mayúsculas, espacios, guiones bajos, sinónimos) y verificar que el motor los mapea correctamente
    - **Valida: Requisitos 2.1, 2.3**

  - [x] 2.3 Implementar ExcelParserService
    - Crear `ExcelParserService.java` en `models/services/`
    - Implementar `parseHeaders(MultipartFile)` que extrae encabezados de la primera fila usando Apache POI
    - Implementar `parseRows(MultipartFile, Map<Integer, String>)` que parsea filas según mapeo y retorna ParseResult (lista de LeadEntity válidos + lista de errores)
    - Manejar tipos de celda (STRING, NUMERIC, DATE, BLANK) correctamente
    - Validar extensión del archivo (.xlsx/.xls) antes de procesar
    - _Requisitos: 1.4, 3.1, 3.3_

  - [x] 2.4 Escribir test de propiedad para validación de extensión de archivo
    - **Propiedad 1: Validación de extensión de archivo**
    - Generar nombres de archivo aleatorios con diversas extensiones y verificar que solo .xlsx y .xls son aceptados (case-insensitive)
    - **Valida: Requisitos 1.4**

  - [x] 2.5 Escribir test de propiedad para importación tolerante a errores
    - **Propiedad 3: Procesamiento de importación con tolerancia a errores**
    - Generar filas con mezcla de datos válidos e inválidos y verificar que se crean exactamente M registros válidos y se reportan (N-M) errores
    - **Valida: Requisitos 3.1, 3.3**

- [x] 3. Implementar servicio de leads y controlador REST en el backend
  - [x] 3.1 Crear interfaz ILeadService e implementación LeadServiceImpl
    - Crear `ILeadService.java` en `models/services/` con métodos: processExcelUpload, confirmImport, findAll(Pageable), searchByTerm, findById, update
    - Crear `LeadServiceImpl.java` implementando la interfaz
    - Inyectar ILeadDao, ILeadImportDao, ExcelParserService, ColumnMappingEngine
    - Implementar lógica de importación: crear LeadImportEntity, parsear filas, guardar leads válidos, actualizar contadores
    - Implementar validación de email y teléfono en el método update
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 7.2, 7.3_

  - [x] 3.2 Escribir test de propiedad para persistencia round-trip
    - **Propiedad 4: Persistencia round-trip de datos del Lead**
    - Generar LeadEntity con datos aleatorios válidos, guardar y recuperar, verificar que todos los campos son idénticos
    - **Valida: Requisitos 3.2, 3.5, 7.3**

  - [x] 3.3 Crear LeadController con endpoints REST
    - Crear `LeadController.java` en `controllers/`
    - Implementar POST `/api/leads/upload` - recibe MultipartFile, retorna MappingPreview (JSON con mapeo, headers, previewRows)
    - Implementar POST `/api/leads/import/confirm` - recibe mapeo confirmado, ejecuta importación, retorna ImportResult
    - Implementar GET `/api/leads` - lista paginada con params: page, size, sort, direction
    - Implementar GET `/api/leads/search` - búsqueda por término con params: term, page, size
    - Implementar GET `/api/leads/{id}` - detalle de un lead
    - Implementar PUT `/api/leads/{id}` - actualización de un lead
    - Implementar GET `/api/leads/imports` - historial de importaciones
    - Configurar validación de permisos de administrador en cada endpoint
    - Manejar errores con códigos HTTP apropiados (400, 403, 404, 413, 500)
    - _Requisitos: 1.2, 1.4, 1.5, 3.1, 4.2, 4.4, 5.2, 5.5, 6.1, 7.3, 8.3_

  - [x] 3.4 Escribir test de propiedad para paginación
    - **Propiedad 5: Invariante de paginación**
    - Generar conjuntos de N leads, solicitar páginas y verificar que cada página tiene máximo 20 registros y la unión de todas las páginas contiene todos los leads sin duplicados
    - **Valida: Requisitos 4.2**

  - [x] 3.5 Escribir test de propiedad para ordenamiento
    - **Propiedad 6: Correctitud del ordenamiento**
    - Generar leads con valores aleatorios, ordenar por cada columna y verificar que cada elemento es ≤ al siguiente
    - **Valida: Requisitos 4.4**

  - [x] 3.6 Escribir test de propiedad para búsqueda
    - **Propiedad 7: Correctitud de la búsqueda**
    - Generar leads y términos de búsqueda, verificar que todos los resultados contienen el término y ningún lead que lo contenga es omitido
    - **Valida: Requisitos 5.2**

  - [x] 3.7 Escribir test de propiedad para validación de email y teléfono
    - **Propiedad 8: Validación de formato de email y teléfono**
    - Generar strings aleatorios y verificar que solo emails con formato válido y teléfonos con caracteres permitidos son aceptados
    - **Valida: Requisitos 7.2**

  - [x] 3.8 Escribir test de propiedad para control de acceso
    - **Propiedad 9: Control de acceso**
    - Generar solicitudes con tokens de diferentes roles y verificar que solo tokens con rol admin son aceptados
    - **Valida: Requisitos 8.1, 8.3**

- [x] 4. Checkpoint - Verificar backend
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 5. Implementar modelos y servicio HTTP en Flutter
  - [x] 5.1 Crear modelo LeadModel en Flutter
    - Crear `lib/features/admin/leads/models/lead_model.dart`
    - Implementar clase LeadModel con campos: id, nombre, apellido, lastCallStatus, pais, telefono, email, campana, fechaRegistro, comentarios, importId, createdAt, updatedAt
    - Implementar factory `fromJson`, método `toJson`, y método `copyWith`
    - _Requisitos: 3.2, 6.1_

  - [x] 5.2 Crear modelo MappingResult en Flutter
    - Crear `lib/features/admin/leads/models/mapping_result.dart`
    - Implementar clase MappingResult con campos: columnMapping (Map<int, String?>), headers (List<String>), previewRows (List<List<String>>), hasUnmappedColumns (bool)
    - Implementar factory `fromJson`
    - _Requisitos: 2.4_

  - [x] 5.3 Crear modelo ImportResult en Flutter
    - Crear `lib/features/admin/leads/models/import_result.dart`
    - Implementar clase ImportResult con campos: successCount, errorCount, totalRows, importId
    - Implementar factory `fromJson`
    - _Requisitos: 3.4_

  - [x] 5.4 Implementar LeadsService para comunicación HTTP
    - Crear `lib/features/admin/leads/services/leads_service.dart`
    - Implementar métodos: uploadExcel(File), confirmImport(Map<int, String?>), getLeads(page, size, sort, direction), searchLeads(term, page, size), getLeadById(id), updateLead(LeadModel), getImportHistory()
    - Utilizar el ApiService existente del proyecto para las llamadas HTTP
    - Manejar multipart upload para el archivo Excel
    - _Requisitos: 1.2, 3.1, 4.2, 4.3, 5.2, 5.5, 6.1, 7.3_

- [x] 6. Implementar BLoC para gestión de estado de leads
  - [x] 6.1 Crear eventos del LeadsBloc
    - Crear `lib/features/admin/leads/bloc/leads_event.dart`
    - Definir eventos: LoadLeads, SearchLeads, UploadExcel, ConfirmImport, LoadLeadDetail, UpdateLead, ClearSearch
    - Cada evento con los parámetros necesarios (page, term, file, mapping, leadId, lead)
    - _Requisitos: 1.2, 4.2, 4.3, 5.1, 6.1, 7.3_

  - [x] 6.2 Crear estados del LeadsBloc
    - Crear `lib/features/admin/leads/bloc/leads_state.dart`
    - Definir estados: LeadsInitial, LeadsLoading, LeadsLoaded, LeadDetailLoaded, MappingPreviewLoaded, ImportCompleted, LeadsError
    - LeadsLoaded incluye: leads, totalPages, currentPage
    - MappingPreviewLoaded incluye: MappingResult
    - ImportCompleted incluye: successCount, errorCount
    - _Requisitos: 1.3, 3.4, 4.2, 5.4_

  - [x] 6.3 Implementar LeadsBloc con manejo de eventos
    - Crear `lib/features/admin/leads/bloc/leads_bloc.dart`
    - Implementar handlers para cada evento usando LeadsService
    - Implementar debounce de 300ms para SearchLeads
    - Manejar errores emitiendo LeadsError con mensaje descriptivo
    - _Requisitos: 1.2, 1.3, 3.1, 4.2, 5.2, 5.3, 6.1, 7.3_

- [x] 7. Implementar pantallas de UI en Flutter
  - [x] 7.1 Crear pantalla de listado de leads (LeadsListScreen)
    - Crear `lib/features/admin/leads/screens/leads_list_screen.dart`
    - Implementar tabla con columnas: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña
    - Implementar paginación con controles de navegación (anterior/siguiente, indicador de página)
    - Implementar ordenamiento por columna al hacer clic en el encabezado
    - Implementar campo de búsqueda con debounce de 300ms
    - Mostrar mensaje "No hay coincidencias" cuando la búsqueda no retorna resultados
    - Incluir botón para navegar a la pantalla de carga de Excel
    - Al hacer clic en una fila, navegar a la vista de detalle
    - _Requisitos: 4.1, 4.2, 4.3, 4.4, 5.1, 5.2, 5.3, 5.4, 6.1_

  - [x] 7.2 Crear pantalla de carga y mapeo de Excel (LeadsUploadScreen)
    - Crear `lib/features/admin/leads/screens/leads_upload_screen.dart`
    - Implementar botón de selección de archivo con filtro para .xlsx/.xls
    - Mostrar indicador de progreso durante la carga
    - Mostrar mensaje de error si el archivo no es .xlsx/.xls o excede 10MB
    - Mostrar vista previa del mapeo automático (tabla con columna Excel → campo del sistema)
    - Permitir edición manual del mapeo para columnas no reconocidas (dropdown con campos disponibles)
    - Implementar botón de confirmación de importación
    - Mostrar resumen de importación (registros exitosos y errores) al finalizar
    - _Requisitos: 1.1, 1.3, 1.4, 1.5, 2.2, 2.4, 2.5, 3.4_

  - [x] 7.3 Crear pantalla de detalle y edición de lead (LeadDetailScreen)
    - Crear `lib/features/admin/leads/screens/lead_detail_screen.dart`
    - Implementar vista de detalle con todos los campos: Nombre, Apellido, Last_Call_Status, País, Teléfono, Email, Campaña, Fecha_de_Registro, Comentarios
    - Implementar modo edición con formulario y validaciones (email, teléfono)
    - Mostrar mensaje de confirmación al guardar exitosamente
    - Mostrar mensaje de error sin perder datos si la actualización falla
    - Implementar botón de cancelar que vuelve a vista de detalle sin guardar
    - _Requisitos: 6.1, 6.2, 6.3, 7.1, 7.2, 7.3, 7.4, 7.5, 7.6_

- [x] 8. Integrar módulo al panel administrativo
  - [x] 8.1 Registrar rutas y navegación del módulo de leads
    - Agregar entrada de navegación "Leads" en el dashboard administrativo existente (`admin_dashboard_screen.dart`)
    - Configurar rutas para las pantallas del módulo de leads
    - Proteger acceso con RoleGuard existente para verificar rol de administrador
    - _Requisitos: 8.1, 8.2_

  - [x] 8.2 Registrar LeadsBloc en el árbol de providers
    - Agregar BlocProvider para LeadsBloc en el punto apropiado del árbol de widgets
    - Asegurar que el LeadsService se inyecta correctamente con el ApiService existente
    - _Requisitos: 4.2, 5.2_

- [x] 9. Checkpoint final - Verificar integración completa
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedad validan propiedades universales de correctitud definidas en el diseño
- Los tests unitarios validan ejemplos específicos y casos borde
- El proyecto backend usa el paquete base `com.bolsadeideas.springboot.backend.apirest`
- El proyecto Flutter sigue el patrón de features en `lib/features/admin/`
- Se reutilizan servicios existentes: ApiService (Flutter), sistema de autenticación JWT (backend)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1"] },
    { "id": 1, "tasks": ["1.2", "1.3"] },
    { "id": 2, "tasks": ["2.1", "2.3"] },
    { "id": 3, "tasks": ["2.2", "2.4", "2.5", "3.1"] },
    { "id": 4, "tasks": ["3.2", "3.3"] },
    { "id": 5, "tasks": ["3.4", "3.5", "3.6", "3.7", "3.8"] },
    { "id": 6, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 7, "tasks": ["5.4"] },
    { "id": 8, "tasks": ["6.1", "6.2"] },
    { "id": 9, "tasks": ["6.3"] },
    { "id": 10, "tasks": ["7.1", "7.2", "7.3"] },
    { "id": 11, "tasks": ["8.1", "8.2"] }
  ]
}
```
