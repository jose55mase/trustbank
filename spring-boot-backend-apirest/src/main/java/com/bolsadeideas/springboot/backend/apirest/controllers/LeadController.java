package com.bolsadeideas.springboot.backend.apirest.controllers;

import java.io.IOException;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.Callable;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.Future;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.stream.Collectors;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.annotation.Secured;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.multipart.MultipartFile;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IAssignmentTypeDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.AssignmentTypeEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadImportEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.ILeadService;
import com.bolsadeideas.springboot.backend.apirest.models.services.ImportResultResponse;
import com.bolsadeideas.springboot.backend.apirest.models.services.LeadExportService;
import com.bolsadeideas.springboot.backend.apirest.models.services.MappingPreviewResponse;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IPermissionService;

/**
 * Controlador REST para la gestión de Leads importados desde archivos Excel.
 * Todos los endpoints requieren rol de administrador.
 */
@RestController
@RequestMapping("/api/leads")
public class LeadController {

    private static final long MAX_FILE_SIZE = 10 * 1024 * 1024; // 10MB

    @Autowired
    private ILeadService leadService;

    @Autowired
    private LeadExportService leadExportService;

    @Autowired
    private ILeadDao leadDao;

    @Autowired
    private IPermissionService permissionService;

    @Autowired
    private IAssignmentTypeDao assignmentTypeDao;

    @Autowired
    private UsuarioService usuarioService;

    /**
     * Resuelve los filter_value strings de las campañas visibles para el usuario actual.
     * 
     * Reglas:
     * - ROLE_ADMIN: retorna null (sin restricciones, ve todo).
     * - Otros roles con campañas asignadas: retorna los filterValues de esas campañas.
     * - Otros roles SIN campañas asignadas: retorna lista con valor imposible (no ve nada).
     */
    private List<String> resolveVisibleCampaignFilterValues() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication == null) {
            return null;
        }

        // Admins have unrestricted access
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
        if (isAdmin) {
            return Collections.emptyList();
        }

        String email = authentication.getName();
        UserEntity user = usuarioService.findByemail(email);
        if (user == null) {
            return null;
        }

        List<Long> campaignIds = permissionService.getUserVisibleCampaignIds(user.getId());
        System.out.println("[CAMPAIGN_FILTER] userId=" + user.getId() + ", email=" + email 
                + ", role=" + (user.getRols() != null && !user.getRols().isEmpty() ? user.getRols().get(0).getName() + "(id=" + user.getRols().get(0).getId() + ")" : "NONE")
                + ", campaignIds=" + campaignIds);

        if (campaignIds == null || campaignIds.isEmpty()) {
            // Non-admin user with no campaigns assigned - should see nothing
            System.out.println("[CAMPAIGN_FILTER] No campaigns for non-admin user, blocking access");
            return Collections.singletonList("__NO_ACCESS__");
        }

        // Look up the filterValue strings for the visible campaign IDs
        List<AssignmentTypeEntity> campaigns = assignmentTypeDao.findAllById(campaignIds);
        List<String> filterValues = campaigns.stream()
                .map(c -> {
                    // Use filterValue if available, otherwise fall back to campaign name
                    String fv = c.getFilterValue();
                    return (fv != null && !fv.trim().isEmpty()) ? fv : c.getName();
                })
                .filter(fv -> fv != null && !fv.trim().isEmpty())
                .collect(Collectors.toList());
        
        if (filterValues.isEmpty()) {
            // Campaigns exist but none have usable filter values - block access
            System.out.println("[CAMPAIGN_FILTER] Campaigns found but no valid filterValues, blocking access");
            return Collections.singletonList("__NO_ACCESS__");
        }
        
        System.out.println("[CAMPAIGN_FILTER] Resolved filterValues=" + filterValues);
        return filterValues;
    }

    /**
     * POST /api/leads/upload
     * Sube un archivo Excel y retorna la vista previa del mapeo de columnas.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @PostMapping("/upload")
    public ResponseEntity<?> uploadExcel(@RequestParam("file") MultipartFile file) {
        Map<String, Object> response = new HashMap<>();

        // Validar que el archivo no esté vacío
        if (file.isEmpty()) {
            response.put("error", "El archivo está vacío");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        // Validar tamaño del archivo (máximo 10MB)
        if (file.getSize() > MAX_FILE_SIZE) {
            response.put("error", "El archivo excede el tamaño máximo de 10MB");
            return new ResponseEntity<>(response, HttpStatus.PAYLOAD_TOO_LARGE);
        }

        // Validar extensión del archivo
        String originalFilename = file.getOriginalFilename();
        if (originalFilename == null || !isValidExcelExtension(originalFilename)) {
            response.put("error", "Formato de archivo no soportado. Use .xlsx o .xls");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            MappingPreviewResponse preview = leadService.processExcelUpload(file);
            return new ResponseEntity<>(preview, HttpStatus.OK);
        } catch (IOException e) {
            response.put("error", "No se pudo leer el archivo Excel: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * POST /api/leads/import/confirm
     * Confirma la importación con el mapeo definido. Recibe el archivo y el mapeo como multipart.
     * Opcionalmente recibe campaignIds para asignar campañas a los leads importados.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @PostMapping("/import/confirm")
    public ResponseEntity<?> confirmImport(
            @RequestParam("file") MultipartFile file,
            @RequestParam("columnMapping") String columnMappingJson,
            @RequestParam("adminId") Long adminId,
            @RequestParam(value = "campaignIds", required = false) List<Long> campaignIds) {

        Map<String, Object> response = new HashMap<>();

        if (file.isEmpty()) {
            response.put("error", "El archivo está vacío");
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        }

        try {
            // Parsear el JSON del mapeo de columnas
            Map<Integer, String> columnMapping = parseColumnMapping(columnMappingJson);

            // Resolver filterValues de las campañas seleccionadas
            List<String> campaignFilterValues = null;
            if (campaignIds != null && !campaignIds.isEmpty()) {
                List<AssignmentTypeEntity> campaigns = assignmentTypeDao.findAllById(campaignIds);
                campaignFilterValues = campaigns.stream()
                        .map(AssignmentTypeEntity::getFilterValue)
                        .filter(fv -> fv != null && !fv.trim().isEmpty())
                        .collect(Collectors.toList());
            }

            ImportResultResponse result = leadService.confirmImport(file, columnMapping, adminId, campaignFilterValues);
            return new ResponseEntity<>(result, HttpStatus.OK);
        } catch (IOException e) {
            response.put("error", "No se pudo leer el archivo Excel: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (IllegalArgumentException e) {
            response.put("error", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/leads/export
     * Genera y descarga un archivo Excel (.xlsx) con todos los leads.
     * Timeout de 30 segundos; retorna HTTP 504 si se excede.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @GetMapping("/export")
    public ResponseEntity<byte[]> exportLeads() {
        try {
            // Generar timestamp para el nombre del archivo
            String timestamp = LocalDateTime.now().format(DateTimeFormatter.ofPattern("yyyyMMdd_HHmmss"));
            String filename = "leads_export_" + timestamp + ".xlsx";

            // Usar un ExecutorService para implementar timeout de 30 segundos
            ExecutorService executor = Executors.newSingleThreadExecutor();
            Future<byte[]> future = executor.submit((Callable<byte[]>) () -> {
                java.io.ByteArrayOutputStream baos = new java.io.ByteArrayOutputStream();
                leadExportService.generateExcelExport(baos);
                return baos.toByteArray();
            });

            byte[] excelData;
            try {
                excelData = future.get(30, TimeUnit.SECONDS);
            } catch (TimeoutException e) {
                future.cancel(true);
                return ResponseEntity.status(HttpStatus.GATEWAY_TIMEOUT).body(null);
            } finally {
                executor.shutdownNow();
            }

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.parseMediaType(
                    "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"));
            headers.set(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=" + filename);
            headers.setContentLength(excelData.length);

            return new ResponseEntity<>(excelData, headers, HttpStatus.OK);

        } catch (ExecutionException e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body(null);
        }
    }

    /**
     * GET /api/leads
     * Lista leads con paginación y ordenamiento.
     * Soporta filtros opcionales:
     * - unassigned=true: retorna solo leads sin asesor asignado
     * - advisorId={id}: retorna solo leads asignados al asesor especificado
     * - pais={pais}: retorna solo leads del país especificado
     * - status={status}: retorna solo leads con el lastCallStatus especificado
     * 
     * Aplica filtrado por campañas visibles según los permisos del usuario.
     * Si el usuario tiene restricciones de campaña, solo se retornan leads
     * cuyo campo 'campana' coincida con los filter_value de las campañas asignadas.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @GetMapping
    public ResponseEntity<?> findAll(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size,
            @RequestParam(defaultValue = "id") String sort,
            @RequestParam(defaultValue = "asc") String direction,
            @RequestParam(required = false) Boolean unassigned,
            @RequestParam(required = false) Long advisorId,
            @RequestParam(required = false) String pais,
            @RequestParam(required = false) String status) {

        try {
            Sort.Direction sortDirection = "desc".equalsIgnoreCase(direction)
                    ? Sort.Direction.DESC : Sort.Direction.ASC;
            Pageable pageable = PageRequest.of(page, size, Sort.by(sortDirection, sort));

            // Resolve campaign visibility filter
            List<String> visibleCampaigns = resolveVisibleCampaignFilterValues();

            // Build dynamic specification
            org.springframework.data.jpa.domain.Specification<LeadEntity> spec = org.springframework.data.jpa.domain.Specification.where(null);

            // Campaign visibility filter
            if (visibleCampaigns != null && !visibleCampaigns.isEmpty()) {
                final List<String> campaigns = visibleCampaigns;
                spec = spec.and((root, query, cb) -> root.get("campana").in(campaigns));
            }

            // Status filter
            if (status != null && !status.trim().isEmpty()) {
                final String statusValue = status.trim();
                spec = spec.and((root, query, cb) -> cb.equal(cb.upper(root.get("lastCallStatus")), statusValue.toUpperCase()));
            }

            // País filter
            if (pais != null && !pais.trim().isEmpty()) {
                final String paisValue = pais.trim();
                spec = spec.and((root, query, cb) -> cb.equal(root.get("pais"), paisValue));
            }

            // Unassigned filter
            if (Boolean.TRUE.equals(unassigned)) {
                spec = spec.and((root, query, cb) -> cb.isNull(root.get("advisor")));
            } else if (advisorId != null) {
                final Long advId = advisorId;
                spec = spec.and((root, query, cb) -> cb.equal(root.get("advisor").get("id"), advId));
            }

            Page<LeadEntity> leads = leadDao.findAll(spec, pageable);
            return new ResponseEntity<>(leads, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/leads/search
     * Busca leads por término en múltiples campos con paginación.
     * Aplica filtrado por campañas visibles según los permisos del usuario.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @GetMapping("/search")
    public ResponseEntity<?> searchByTerm(
            @RequestParam String term,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        try {
            Pageable pageable = PageRequest.of(page, size);

            // Resolve campaign visibility filter
            List<String> visibleCampaigns = resolveVisibleCampaignFilterValues();

            Page<LeadEntity> leads;

            if (visibleCampaigns != null && !visibleCampaigns.isEmpty()) {
                // User has campaign restrictions - apply campaign filtering to search
                leads = leadDao.searchByCampanaInAndTerm(visibleCampaigns, term, pageable);
            } else {
                // No campaign restrictions - use existing unfiltered search
                leads = leadService.searchByTerm(term, pageable);
            }

            return new ResponseEntity<>(leads, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/leads/{id}
     * Obtiene el detalle de un lead por su ID.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @GetMapping("/{id:\\d+}")
    public ResponseEntity<?> findById(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            LeadEntity lead = leadService.findById(id);

            // Enforce campaign-based access control
            List<String> visibleCampaigns = resolveVisibleCampaignFilterValues();
            if (visibleCampaigns != null && !visibleCampaigns.isEmpty()) {
                String leadCampana = lead.getCampana();
                if (leadCampana == null || !visibleCampaigns.contains(leadCampana)) {
                    response.put("error", "CAMPAIGN_ACCESS_DENIED");
                    response.put("message", "No tienes acceso a este lead");
                    return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
                }
            }

            return new ResponseEntity<>(lead, HttpStatus.OK);
        } catch (RuntimeException e) {
            response.put("error", "Lead no encontrado");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * PUT /api/leads/{id}
     * Actualiza un lead existente.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @PutMapping("/{id:\\d+}")
    public ResponseEntity<?> update(@PathVariable Long id, @RequestBody LeadEntity lead) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Retrieve existing lead to check campaign access
            LeadEntity existingLead = leadService.findById(id);

            // Enforce campaign-based access control
            List<String> visibleCampaigns = resolveVisibleCampaignFilterValues();
            if (visibleCampaigns != null && !visibleCampaigns.isEmpty()) {
                String leadCampana = existingLead.getCampana();
                if (leadCampana == null || !visibleCampaigns.contains(leadCampana)) {
                    response.put("error", "CAMPAIGN_ACCESS_DENIED");
                    response.put("message", "No tienes acceso a este lead");
                    return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
                }
            }

            LeadEntity updatedLead = leadService.update(id, lead);
            return new ResponseEntity<>(updatedLead, HttpStatus.OK);
        } catch (IllegalArgumentException e) {
            response.put("error", e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
        } catch (RuntimeException e) {
            response.put("error", "Lead no encontrado");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * DELETE /api/leads/{id}
     * Elimina un lead por su ID.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @DeleteMapping("/{id:\\d+}")
    public ResponseEntity<?> delete(@PathVariable Long id) {
        Map<String, Object> response = new HashMap<>();

        try {
            // Retrieve existing lead to check campaign access before deletion
            LeadEntity existingLead = leadService.findById(id);

            // Enforce campaign-based access control
            List<String> visibleCampaigns = resolveVisibleCampaignFilterValues();
            if (visibleCampaigns != null && !visibleCampaigns.isEmpty()) {
                String leadCampana = existingLead.getCampana();
                if (leadCampana == null || !visibleCampaigns.contains(leadCampana)) {
                    response.put("error", "CAMPAIGN_ACCESS_DENIED");
                    response.put("message", "No tienes acceso a este lead");
                    return new ResponseEntity<>(response, HttpStatus.FORBIDDEN);
                }
            }

            leadService.delete(id);
            response.put("mensaje", "Lead eliminado exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
        } catch (RuntimeException e) {
            response.put("error", "Lead no encontrado");
            return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
        } catch (Exception e) {
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * GET /api/leads/imports
     * Lista el historial de importaciones con paginación.
     */
    // Access controlled by ModuleAccessFilter (LEADS module)
    @GetMapping("/imports")
    public ResponseEntity<?> getImportHistory(
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "20") int size) {

        try {
            Pageable pageable = PageRequest.of(page, size, Sort.by(Sort.Direction.DESC, "createdAt"));
            Page<LeadImportEntity> imports = leadService.getImportHistory(pageable);
            return new ResponseEntity<>(imports, HttpStatus.OK);
        } catch (Exception e) {
            Map<String, Object> response = new HashMap<>();
            response.put("error", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    /**
     * Valida que la extensión del archivo sea .xlsx o .xls (case-insensitive).
     */
    private boolean isValidExcelExtension(String filename) {
        String lowerFilename = filename.toLowerCase();
        return lowerFilename.endsWith(".xlsx") || lowerFilename.endsWith(".xls");
    }

    /**
     * Parsea el JSON del mapeo de columnas a un Map<Integer, String>.
     * Formato esperado: {"0":"nombre","1":"apellido","2":null,...}
     */
    private Map<Integer, String> parseColumnMapping(String json) {
        Map<Integer, String> mapping = new HashMap<>();

        // Remover llaves externas
        String content = json.trim();
        if (content.startsWith("{")) {
            content = content.substring(1);
        }
        if (content.endsWith("}")) {
            content = content.substring(0, content.length() - 1);
        }

        if (content.trim().isEmpty()) {
            return mapping;
        }

        // Parsear pares key:value
        String[] pairs = content.split(",");
        for (String pair : pairs) {
            String[] keyValue = pair.split(":", 2);
            if (keyValue.length == 2) {
                String key = keyValue[0].trim().replace("\"", "");
                String value = keyValue[1].trim().replace("\"", "");

                try {
                    Integer index = Integer.parseInt(key);
                    if ("null".equals(value) || value.isEmpty()) {
                        mapping.put(index, null);
                    } else {
                        mapping.put(index, value);
                    }
                } catch (NumberFormatException e) {
                    // Ignorar entradas con clave no numérica
                }
            }
        }

        return mapping;
    }
}
