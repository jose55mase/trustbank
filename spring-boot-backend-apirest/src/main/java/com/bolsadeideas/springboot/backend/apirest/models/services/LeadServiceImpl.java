package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadImportDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadImportEntity;

/**
 * Implementación del servicio de gestión de Leads.
 * Maneja la importación desde Excel, consultas paginadas, búsqueda y actualización con validaciones.
 */
@Service
public class LeadServiceImpl implements ILeadService {

    private static final String EMAIL_REGEX = "^[\\w.-]+@[\\w.-]+\\.[a-zA-Z]{2,}$";
    private static final String PHONE_REGEX = "^[\\d+\\-\\s()]{7,20}$";

    @Autowired
    private ILeadDao leadDao;

    @Autowired
    private ILeadImportDao leadImportDao;

    @Autowired
    private ExcelParserService excelParserService;

    @Autowired
    private ColumnMappingEngine columnMappingEngine;

    @Autowired
    private DeduplicationEngine deduplicationEngine;

    @Override
    @Transactional(readOnly = true)
    public MappingPreviewResponse processExcelUpload(MultipartFile file) throws IOException {
        // Validar extensión del archivo
        excelParserService.validateFileExtension(file.getOriginalFilename());

        // Parsear encabezados
        List<String> headers = excelParserService.parseHeaders(file);

        // Ejecutar motor de mapeo
        MappingResult mappingResult = columnMappingEngine.mapColumns(headers);

        // Obtener las primeras 5 filas como preview
        List<List<String>> previewRows = getPreviewRows(file, 5);

        return new MappingPreviewResponse(
                headers,
                mappingResult.getColumnMapping(),
                previewRows,
                mappingResult.isHasUnmappedColumns()
        );
    }

    @Override
    @Transactional
    public ImportResultResponse confirmImport(MultipartFile file, Map<Integer, String> columnMapping, Long adminId) throws IOException {
        // Crear registro de importación con estado PROCESSING
        LeadImportEntity importEntity = new LeadImportEntity();
        importEntity.setFileName(file.getOriginalFilename());
        importEntity.setAdminId(adminId);
        importEntity.setStatus("PROCESSING");
        importEntity.setTotalRows(0);
        importEntity.setSuccessCount(0);
        importEntity.setErrorCount(0);
        importEntity.setDuplicateCount(0);
        importEntity = leadImportDao.save(importEntity);

        // Parsear filas con el mapeo proporcionado
        ParseResult parseResult = excelParserService.parseRows(file, columnMapping);

        // Filtrar duplicados de los leads válidos
        List<LeadEntity> validLeads = parseResult.getValidLeads();
        DeduplicationResult deduplicationResult = deduplicationEngine.filterDuplicates(validLeads);

        // Guardar solo los leads únicos (no duplicados) con el importId
        List<LeadEntity> uniqueLeads = deduplicationResult.getUniqueLeads();
        for (LeadEntity lead : uniqueLeads) {
            lead.setImportId(importEntity.getId());
        }
        leadDao.saveAll(uniqueLeads);

        // Guardar los leads actualizados (duplicados cuyos datos cambiaron)
        List<LeadEntity> updatedLeads = deduplicationResult.getUpdatedLeads();
        if (!updatedLeads.isEmpty()) {
            leadDao.saveAll(updatedLeads);
        }

        // Calcular contadores garantizando invariante: successCount + duplicateCount + errorCount == totalRows
        int successCount = uniqueLeads.size();
        int duplicateCount = deduplicationResult.getDuplicateCount();
        int errorCount = parseResult.getErrorCount();
        int totalRows = successCount + duplicateCount + errorCount;

        // Actualizar entidad de importación con todos los contadores
        importEntity.setTotalRows(totalRows);
        importEntity.setSuccessCount(successCount);
        importEntity.setErrorCount(errorCount);
        importEntity.setDuplicateCount(duplicateCount);
        importEntity.setStatus("COMPLETED");
        leadImportDao.save(importEntity);

        return new ImportResultResponse(successCount, errorCount, duplicateCount, totalRows, importEntity.getId());
    }

    @Override
    @Transactional(readOnly = true)
    public Page<LeadEntity> findAll(Pageable pageable) {
        return leadDao.findAll(pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<LeadEntity> searchByTerm(String term, Pageable pageable) {
        return leadDao.searchByTerm(term, pageable);
    }

    @Override
    @Transactional(readOnly = true)
    public LeadEntity findById(Long id) {
        return leadDao.findById(id).orElseThrow(
                () -> new RuntimeException("Lead no encontrado con ID: " + id)
        );
    }

    @Override
    @Transactional
    public LeadEntity update(Long id, LeadEntity lead) {
        LeadEntity existingLead = findById(id);

        // Validar email si se proporciona
        if (lead.getEmail() != null && !lead.getEmail().trim().isEmpty()) {
            if (!lead.getEmail().matches(EMAIL_REGEX)) {
                throw new IllegalArgumentException("Formato de email inválido: " + lead.getEmail());
            }
        }

        // Validar teléfono si se proporciona
        if (lead.getTelefono() != null && !lead.getTelefono().trim().isEmpty()) {
            if (!lead.getTelefono().matches(PHONE_REGEX)) {
                throw new IllegalArgumentException(
                        "Formato de teléfono inválido. Debe contener entre 7 y 20 caracteres, solo dígitos, +, -, espacios y paréntesis.");
            }
        }

        // Actualizar campos
        existingLead.setNombre(lead.getNombre());
        existingLead.setApellido(lead.getApellido());
        existingLead.setLastCallStatus(lead.getLastCallStatus());
        existingLead.setPais(lead.getPais());
        existingLead.setTelefono(lead.getTelefono());
        existingLead.setEmail(lead.getEmail());
        existingLead.setCampana(lead.getCampana());
        existingLead.setFechaRegistro(lead.getFechaRegistro());
        existingLead.setComentarios(lead.getComentarios());
        existingLead.setLastCallDate(lead.getLastCallDate());

        return leadDao.save(existingLead);
    }

    @Override
    @Transactional(readOnly = true)
    public Page<LeadImportEntity> getImportHistory(Pageable pageable) {
        return leadImportDao.findAll(pageable);
    }

    @Override
    @Transactional
    public void delete(Long id) {
        LeadEntity lead = leadDao.findById(id).orElseThrow(
                () -> new RuntimeException("Lead no encontrado con ID: " + id)
        );
        leadDao.delete(lead);
    }

    /**
     * Obtiene las primeras N filas de datos del archivo Excel como listas de strings.
     * Se usa para generar la vista previa del mapeo.
     */
    private List<List<String>> getPreviewRows(MultipartFile file, int maxRows) throws IOException {
        List<List<String>> rows = new ArrayList<>();

        try (InputStream is = file.getInputStream();
             Workbook workbook = WorkbookFactory.create(is)) {

            Sheet sheet = workbook.getSheetAt(0);
            int lastRowNum = sheet.getLastRowNum();
            int rowCount = Math.min(lastRowNum, maxRows);

            // Start from row 1 (skip header row)
            for (int rowIndex = 1; rowIndex <= rowCount; rowIndex++) {
                Row row = sheet.getRow(rowIndex);
                if (row == null) {
                    continue;
                }

                List<String> rowData = new ArrayList<>();
                int lastCellNum = row.getLastCellNum();
                for (int cellIndex = 0; cellIndex < lastCellNum; cellIndex++) {
                    Cell cell = row.getCell(cellIndex);
                    rowData.add(getCellValueAsString(cell));
                }
                rows.add(rowData);
            }
        }

        return rows;
    }

    /**
     * Obtiene el valor de una celda como String para la vista previa.
     */
    private String getCellValueAsString(Cell cell) {
        if (cell == null) {
            return "";
        }

        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                if (org.apache.poi.ss.usermodel.DateUtil.isCellDateFormatted(cell)) {
                    return cell.getDateCellValue() != null ? cell.getDateCellValue().toString() : "";
                }
                double numericValue = cell.getNumericCellValue();
                if (numericValue == Math.floor(numericValue) && !Double.isInfinite(numericValue)) {
                    return String.valueOf((long) numericValue);
                }
                return String.valueOf(numericValue);
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case BLANK:
                return "";
            default:
                return "";
        }
    }
}
