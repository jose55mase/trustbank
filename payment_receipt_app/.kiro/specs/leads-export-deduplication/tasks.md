# Plan de Implementación: Exportación y Deduplicación de Leads

## Resumen

Este plan implementa dos funcionalidades complementarias para el módulo de leads existente: (1) un motor de deduplicación que detecta y omite registros duplicados durante la importación basándose en email o teléfono normalizado, y (2) un endpoint de exportación que genera un archivo Excel (.xlsx) con todos los leads usando streaming eficiente. Las tareas cubren: migración de base de datos, nuevos componentes backend (DeduplicationEngine, LeadExportService), modificaciones al flujo de importación existente, endpoint REST de exportación, y actualizaciones en el frontend Flutter (modelo, BLoC, servicio, pantallas).

## Tareas

- [x] 1. Extender modelo de datos y migración en el backend
  - [x] 1.1 Agregar campo duplicateCount a LeadImportEntity y crear migración SQL
    - Agregar campo `duplicateCount` (Integer) con anotación `@Column(name = "duplicate_count")` a `LeadImportEntity.java`
    - Agregar getter y setter para el nuevo campo
    - Crear script de migración SQL: `ALTER TABLE lead_imports ADD COLUMN duplicate_count INT DEFAULT 0;`
    - _Requisitos: 4.4_

  - [x] 1.2 Actualizar ImportResultResponse para incluir duplicateCount
    - Agregar campo `private int duplicateCount` a `ImportResultResponse.java`
    - Actualizar constructor para aceptar el nuevo parámetro: `(int successCount, int errorCount, int duplicateCount, int totalRows, Long importId)`
    - Agregar getter y setter para duplicateCount
    - Verificar que la serialización JSON incluye el campo correctamente
    - _Requisitos: 4.1, 4.3_

- [x] 2. Implementar consultas de deduplicación en ILeadDao
  - [x] 2.1 Agregar queries findAllNormalizedEmails y findAllPhones a ILeadDao
    - Agregar método `@Query("SELECT LOWER(TRIM(l.email)) FROM LeadEntity l WHERE l.email IS NOT NULL AND TRIM(l.email) <> ''") List<String> findAllNormalizedEmails();`
    - Agregar método `@Query("SELECT l.telefono FROM LeadEntity l WHERE l.telefono IS NOT NULL AND TRIM(l.telefono) <> ''") List<String> findAllPhones();`
    - Agregar import de `Sort` y método `List<LeadEntity> findAll(Sort sort);` si no existe
    - _Requisitos: 2.1, 2.2, 2.3_

- [x] 3. Implementar DeduplicationEngine en el backend
  - [x] 3.1 Crear clase DeduplicationEngine con lógica de normalización y filtrado
    - Crear `DeduplicationEngine.java` en `models/services/`
    - Anotar con `@Component` e inyectar `ILeadDao`
    - Implementar `normalizeEmail(String email)`: trim + lowercase, retorna null si vacío/null
    - Implementar `normalizePhone(String phone)`: elimina espacios, guiones y paréntesis, retorna null si vacío/null
    - Implementar `filterDuplicates(List<LeadEntity> candidates)` que:
      1. Carga todos los emails normalizados existentes en un Set (vía `findAllNormalizedEmails()`)
      2. Carga todos los teléfonos normalizados existentes en un Set (vía `findAllPhones()`, normalizando cada uno)
      3. Itera candidatos: si email normalizado está en Set OR teléfono normalizado está en Set → duplicado
      4. Maneja deduplicación intra-archivo con Sets locales de emails/teléfonos ya vistos
      5. Si email y teléfono son ambos vacíos/null → no es duplicado (se importa)
    - Crear clase `DeduplicationResult` con campos: uniqueLeads, duplicateLeads, duplicateCount
    - _Requisitos: 2.1, 2.2, 2.3, 2.4, 2.7, 2.8, 2.9, 2.10_

  - [x]* 3.2 Escribir test de propiedad para normalización de email
    - **Propiedad 2: Normalización de email es idempotente y case-insensitive**
    - Generar strings aleatorios con variaciones de case y whitespace
    - Verificar: `normalizeEmail(e) == normalizeEmail(normalizeEmail(e))` (idempotencia)
    - Verificar: emails que difieren solo en case/whitespace producen el mismo resultado
    - **Valida: Requisitos 2.2**

  - [x]* 3.3 Escribir test de propiedad para normalización de teléfono
    - **Propiedad 3: Normalización de teléfono es idempotente y elimina caracteres de formato**
    - Generar strings con dígitos + mezcla aleatoria de espacios/guiones/paréntesis
    - Verificar: `normalizePhone(p) == normalizePhone(normalizePhone(p))` (idempotencia)
    - Verificar: teléfonos que difieren solo en formato producen el mismo resultado
    - **Valida: Requisitos 2.3**

  - [x]* 3.4 Escribir test de propiedad para deduplicación contra base de datos
    - **Propiedad 4: Deduplicación excluye leads con email O teléfono coincidente**
    - Generar pares (existingLeads, candidateLeads) con solapamiento parcial
    - Verificar: candidato es duplicado ↔ email normalizado coincide OR teléfono normalizado coincide
    - Verificar: candidatos con ambos campos vacíos nunca son duplicados
    - **Valida: Requisitos 2.1, 2.4, 2.7, 2.8, 2.10**

  - [x]* 3.5 Escribir test de propiedad para deduplicación intra-archivo
    - **Propiedad 5: Deduplicación intra-archivo preserva solo la primera ocurrencia**
    - Generar listas con filas repetidas en posiciones aleatorias
    - Verificar: solo la primera ocurrencia pasa el filtro, las subsiguientes son duplicadas
    - **Valida: Requisitos 2.9**

- [x] 4. Implementar LeadExportService en el backend
  - [x] 4.1 Crear LeadExportService con generación de Excel usando SXSSFWorkbook
    - Crear `LeadExportService.java` en `models/services/`
    - Anotar con `@Service` e inyectar `ILeadDao`
    - Implementar `generateExcelExport(OutputStream outputStream)` que:
      1. Consulta todos los leads ordenados por fechaRegistro DESC usando `findAll(Sort.by(Sort.Direction.DESC, "fechaRegistro"))`
      2. Crea SXSSFWorkbook con window size de 100 filas
      3. Escribe fila de encabezados: Nombre, Apellido, Last Call Status, País, Teléfono, Email, Campaña, Fecha de Registro, Comentarios
      4. Itera leads escribiendo una fila por cada uno con formato de fecha dd/MM/yyyy
      5. Escribe al OutputStream y cierra el workbook
    - Si no hay leads, retorna archivo con solo encabezados
    - _Requisitos: 1.2, 1.3, 1.4, 3.1, 3.2, 3.4_

  - [x]* 4.2 Escribir test de propiedad para round-trip de exportación
    - **Propiedad 1: Round-trip de exportación preserva todos los leads**
    - Generar listas aleatorias de LeadEntity (0-500 leads) con campos string aleatorios y fechas
    - Parsear el .xlsx generado y verificar que el número de filas == número de leads
    - Verificar que cada lead está representado con sus campos correctos
    - **Valida: Requisitos 1.2, 1.4, 3.1**

  - [x]* 4.3 Escribir test de propiedad para ordenamiento de exportación
    - **Propiedad 7: Exportación ordena leads por fecha de registro descendente**
    - Generar leads con fechas aleatorias distintas
    - Exportar y verificar que cada fila tiene fecha >= a la fila siguiente (orden descendente)
    - **Valida: Requisitos 3.1**

- [x] 5. Integrar DeduplicationEngine en el flujo de importación
  - [x] 5.1 Modificar LeadServiceImpl.confirmImport para integrar DeduplicationEngine
    - Inyectar `DeduplicationEngine` en `LeadServiceImpl`
    - Modificar método `confirmImport()` para:
      1. Después de `excelParserService.parseRows()`, invocar `deduplicationEngine.filterDuplicates(validLeads)`
      2. Guardar solo `deduplicationResult.getUniqueLeads()` en la base de datos
      3. Calcular: successCount = uniqueLeads.size(), duplicateCount = deduplicationResult.getDuplicateCount(), errorCount = parseResult.getErrorCount()
      4. Actualizar LeadImportEntity con el nuevo campo duplicateCount
      5. Retornar `ImportResultResponse` con los 5 parámetros (incluyendo duplicateCount)
    - Garantizar invariante: successCount + duplicateCount + errorCount == totalRows
    - _Requisitos: 2.1, 2.4, 2.5, 4.1, 4.3, 4.4_

  - [x]* 5.2 Escribir test de propiedad para invariante aritmética del resumen
    - **Propiedad 6: Invariante aritmética del resumen de importación**
    - Generar escenarios aleatorios con mezcla de válidos, duplicados y errores
    - Verificar: `successCount + duplicateCount + errorCount == totalRows`
    - **Valida: Requisitos 2.5, 4.1, 4.3**

- [x] 6. Agregar endpoint de exportación al LeadController
  - [x] 6.1 Implementar endpoint GET /api/leads/export en LeadController
    - Inyectar `LeadExportService` en `LeadController`
    - Implementar método `exportLeads()` con anotaciones `@Secured("ROLE_ADMIN")` y `@GetMapping("/export")`
    - Retornar `ResponseEntity<StreamingResponseBody>` con:
      - Content-Type: `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`
      - Content-Disposition: `attachment; filename=leads_export_YYYYMMDD_HHmmss.xlsx`
    - Implementar timeout de 30 segundos; si se excede, retornar HTTP 504 con mensaje de error
    - Manejar errores internos retornando HTTP 500 con mensaje genérico
    - _Requisitos: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7, 3.8_

- [x] 7. Checkpoint - Verificar backend completo
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

- [x] 8. Actualizar modelo ImportResult en Flutter
  - [x] 8.1 Agregar campo duplicateCount al modelo ImportResult
    - Agregar campo `final int duplicateCount` a la clase `ImportResult`
    - Actualizar constructor para incluir `required this.duplicateCount`
    - Actualizar factory `fromJson` para parsear `json['duplicateCount'] ?? 0`
    - _Requisitos: 4.1, 4.2_

- [x] 9. Implementar exportación en el BLoC y servicio Flutter
  - [x] 9.1 Agregar evento ExportLeads y estados de exportación al LeadsBloc
    - Agregar evento `ExportLeads` en `leads_event.dart`
    - Agregar estados `ExportInProgress` y `ExportCompleted` (con campo `String filePath`) en `leads_state.dart`
    - Modificar estado `ImportCompleted` para incluir campo `duplicateCount`
    - Implementar handler `_onExportLeads` en `leads_bloc.dart` que:
      1. Emite `ExportInProgress`
      2. Llama a `LeadsService.exportLeads()`
      3. Guarda archivo en directorio de descargas
      4. Emite `ExportCompleted(filePath: path)` o `LeadsError` en caso de fallo
    - _Requisitos: 1.1, 1.5, 1.6, 1.7_

  - [x] 9.2 Agregar método exportLeads al LeadsService
    - Implementar método estático `exportLeads()` en `LeadsService`:
      ```dart
      static Future<List<int>> exportLeads() async {
        final response = await http.get(
          Uri.parse('$_baseUrl/leads/export'),
          headers: await _headers,
        );
        if (response.statusCode == 200) {
          return response.bodyBytes;
        } else {
          throw Exception('Error al exportar leads: ${response.statusCode}');
        }
      }
      ```
    - Manejar timeout de 60 segundos en el cliente HTTP
    - _Requisitos: 1.2, 1.9, 3.1_

- [x] 10. Actualizar pantallas Flutter con exportación y resumen de duplicados
  - [x] 10.1 Agregar botón de exportación a LeadsListScreen
    - Agregar `IconButton` con icono `Icons.download` en las `actions` del AppBar, junto al botón existente de "Cargar Excel"
    - Al presionar, despachar evento `ExportLeads` al BLoC
    - Escuchar estado `ExportInProgress`: mostrar indicador de carga y deshabilitar botón
    - Escuchar estado `ExportCompleted`: mostrar Snackbar de éxito con nombre del archivo y rehabilitar botón
    - Escuchar `LeadsError` durante exportación: mostrar Snackbar con mensaje de error y rehabilitar botón
    - _Requisitos: 1.1, 1.5, 1.6, 1.7, 1.8_

  - [x] 10.2 Actualizar resumen de importación en LeadsUploadScreen para mostrar duplicateCount
    - Modificar método `_buildImportSummary` para aceptar 3 parámetros: successCount, duplicateCount, errorCount
    - Agregar fila de resumen con icono `Icons.content_copy`, color naranja, etiqueta "Duplicados omitidos" y conteo de duplicateCount
    - Actualizar el `BlocConsumer` para pasar `state.duplicateCount` al resumen
    - Mantener las filas existentes de "Registros exitosos" y "Registros con errores"
    - _Requisitos: 2.5, 2.6, 4.2_

- [x] 11. Checkpoint final - Verificar integración completa
  - Asegurar que todos los tests pasan, preguntar al usuario si surgen dudas.

## Notas

- Las tareas marcadas con `*` son opcionales y pueden omitirse para un MVP más rápido
- Cada tarea referencia requisitos específicos para trazabilidad
- Los checkpoints aseguran validación incremental
- Los tests de propiedad validan propiedades universales de correctitud definidas en el diseño (jqwik para Java)
- El proyecto backend usa el paquete base `com.bolsadeideas.springboot.backend.apirest`
- El proyecto Flutter sigue el patrón de features en `lib/features/admin/leads/`
- Apache POI (SXSSFWorkbook) ya está configurado en el proyecto para streaming eficiente
- La deduplicación se ejecuta en capa de servicio (no en DB) para permitir normalización compleja de teléfonos
- Se reutiliza la infraestructura existente: autenticación JWT, roles, servicios HTTP

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "2.1"] },
    { "id": 1, "tasks": ["3.1", "4.1"] },
    { "id": 2, "tasks": ["3.2", "3.3", "3.4", "3.5", "4.2", "4.3"] },
    { "id": 3, "tasks": ["5.1", "6.1"] },
    { "id": 4, "tasks": ["5.2", "8.1"] },
    { "id": 5, "tasks": ["9.1", "9.2"] },
    { "id": 6, "tasks": ["10.1", "10.2"] }
  ]
}
```
