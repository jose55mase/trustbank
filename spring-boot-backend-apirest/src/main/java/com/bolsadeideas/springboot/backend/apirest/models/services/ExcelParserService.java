package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.io.IOException;
import java.io.InputStream;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Map;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.CellType;
import org.apache.poi.ss.usermodel.DateUtil;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.ss.usermodel.WorkbookFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

/**
 * Servicio para parsear archivos Excel usando Apache POI.
 * Extrae encabezados y filas, mapeándolos a entidades LeadEntity.
 */
@Service
public class ExcelParserService {

    /**
     * Validates that the file has a valid Excel extension (.xlsx or .xls, case-insensitive).
     * Throws IllegalArgumentException if invalid.
     */
    public void validateFileExtension(String fileName) {
        if (fileName == null || fileName.isEmpty()) {
            throw new IllegalArgumentException("El nombre del archivo no puede estar vacío");
        }

        String lowerName = fileName.toLowerCase();
        if (!lowerName.endsWith(".xlsx") && !lowerName.endsWith(".xls")) {
            throw new IllegalArgumentException(
                    "Formato de archivo no soportado. Use .xlsx o .xls");
        }
    }

    /**
     * Extrae los encabezados de la primera fila del archivo Excel.
     */
    public List<String> parseHeaders(MultipartFile file) throws IOException {
        validateFileExtension(file.getOriginalFilename());

        List<String> headers = new ArrayList<>();

        try (InputStream is = file.getInputStream();
             Workbook workbook = WorkbookFactory.create(is)) {

            Sheet sheet = workbook.getSheetAt(0);
            Row headerRow = sheet.getRow(0);

            if (headerRow == null) {
                return headers;
            }

            for (int i = 0; i < headerRow.getLastCellNum(); i++) {
                Cell cell = headerRow.getCell(i);
                String headerValue = getCellValueAsString(cell);
                headers.add(headerValue != null ? headerValue.trim() : "");
            }
        }

        return headers;
    }

    /**
     * Parsea todas las filas del Excel según el mapeo proporcionado.
     * Retorna ParseResult con lista de LeadEntity válidos + lista de errores.
     */
    public ParseResult parseRows(MultipartFile file, Map<Integer, String> columnMapping) throws IOException {
        validateFileExtension(file.getOriginalFilename());

        ParseResult result = new ParseResult();

        try (InputStream is = file.getInputStream();
             Workbook workbook = WorkbookFactory.create(is)) {

            Sheet sheet = workbook.getSheetAt(0);
            int lastRowNum = sheet.getLastRowNum();

            // Start from row 1 (skip header row)
            for (int rowIndex = 1; rowIndex <= lastRowNum; rowIndex++) {
                Row row = sheet.getRow(rowIndex);

                if (row == null || isRowBlank(row)) {
                    continue;
                }

                try {
                    LeadEntity lead = parseRowToLead(row, columnMapping);
                    result.addValidLead(lead);
                } catch (Exception e) {
                    result.addError("Fila " + (rowIndex + 1) + ": " + e.getMessage());
                }
            }
        }

        return result;
    }

    /**
     * Parsea una fila individual del Excel y la convierte en un LeadEntity.
     * Lanza IllegalArgumentException si la fila no contiene datos mínimos requeridos
     * (al menos nombre o email deben estar presentes).
     */
    private LeadEntity parseRowToLead(Row row, Map<Integer, String> columnMapping) {
        LeadEntity lead = new LeadEntity();

        for (Map.Entry<Integer, String> entry : columnMapping.entrySet()) {
            int columnIndex = entry.getKey();
            String fieldName = entry.getValue();

            if (fieldName == null || fieldName.isEmpty()) {
                continue;
            }

            Cell cell = row.getCell(columnIndex);

            if ("fechaRegistro".equals(fieldName)) {
                Date dateValue = getCellValueAsDate(cell);
                lead.setFechaRegistro(dateValue);
            } else {
                String value = getCellValueAsString(cell);
                setLeadField(lead, fieldName, value);
            }
        }

        // Validate that the row has minimum required data
        boolean hasNombre = lead.getNombre() != null && !lead.getNombre().trim().isEmpty();
        boolean hasEmail = lead.getEmail() != null && !lead.getEmail().trim().isEmpty();

        if (!hasNombre && !hasEmail) {
            throw new IllegalArgumentException(
                "La fila no contiene datos mínimos requeridos (nombre o email)");
        }

        return lead;
    }

    /**
     * Asigna un valor String al campo correspondiente del LeadEntity.
     */
    private void setLeadField(LeadEntity lead, String fieldName, String value) {
        switch (fieldName) {
            case "nombre":
                lead.setNombre(value);
                break;
            case "apellido":
                lead.setApellido(value);
                break;
            case "lastCallStatus":
                lead.setLastCallStatus(value);
                break;
            case "pais":
                lead.setPais(value);
                break;
            case "telefono":
                lead.setTelefono(value);
                break;
            case "email":
                lead.setEmail(value);
                break;
            case "campana":
                lead.setCampana(value);
                break;
            case "comentarios":
                lead.setComentarios(value);
                break;
            case "fechaRegistro":
                // Handled separately in parseRowToLead
                break;
            default:
                // Unknown field, ignore
                break;
        }
    }

    /**
     * Obtiene el valor de una celda como String, manejando diferentes tipos de celda.
     */
    private String getCellValueAsString(Cell cell) {
        if (cell == null) {
            return null;
        }

        switch (cell.getCellType()) {
            case STRING:
                return cell.getStringCellValue();
            case NUMERIC:
                if (DateUtil.isCellDateFormatted(cell)) {
                    Date date = cell.getDateCellValue();
                    return date != null ? date.toString() : null;
                }
                // Format numeric values to avoid scientific notation and trailing .0
                double numericValue = cell.getNumericCellValue();
                if (numericValue == Math.floor(numericValue) && !Double.isInfinite(numericValue)) {
                    return String.valueOf((long) numericValue);
                }
                return String.valueOf(numericValue);
            case BOOLEAN:
                return String.valueOf(cell.getBooleanCellValue());
            case FORMULA:
                try {
                    return cell.getStringCellValue();
                } catch (Exception e) {
                    try {
                        double formulaNumeric = cell.getNumericCellValue();
                        if (formulaNumeric == Math.floor(formulaNumeric) && !Double.isInfinite(formulaNumeric)) {
                            return String.valueOf((long) formulaNumeric);
                        }
                        return String.valueOf(formulaNumeric);
                    } catch (Exception e2) {
                        return null;
                    }
                }
            case BLANK:
                return null;
            default:
                return null;
        }
    }

    /**
     * Obtiene el valor de una celda como Date.
     */
    private Date getCellValueAsDate(Cell cell) {
        if (cell == null) {
            return null;
        }

        switch (cell.getCellType()) {
            case NUMERIC:
                if (DateUtil.isCellDateFormatted(cell)) {
                    return cell.getDateCellValue();
                }
                // Try to interpret numeric value as a date
                return DateUtil.getJavaDate(cell.getNumericCellValue());
            case STRING:
                // Try to parse string as date - return null if not parseable
                String dateStr = cell.getStringCellValue();
                if (dateStr == null || dateStr.trim().isEmpty()) {
                    return null;
                }
                // Attempt common date formats
                return tryParseDate(dateStr.trim());
            case BLANK:
                return null;
            default:
                return null;
        }
    }

    /**
     * Intenta parsear un string como fecha usando formatos comunes.
     */
    private Date tryParseDate(String dateStr) {
        java.text.SimpleDateFormat[] formats = {
                new java.text.SimpleDateFormat("yyyy-MM-dd"),
                new java.text.SimpleDateFormat("dd/MM/yyyy"),
                new java.text.SimpleDateFormat("MM/dd/yyyy"),
                new java.text.SimpleDateFormat("dd-MM-yyyy"),
                new java.text.SimpleDateFormat("yyyy/MM/dd"),
                new java.text.SimpleDateFormat("dd.MM.yyyy")
        };

        for (java.text.SimpleDateFormat format : formats) {
            try {
                format.setLenient(false);
                return format.parse(dateStr);
            } catch (java.text.ParseException e) {
                // Try next format
            }
        }

        return null;
    }

    /**
     * Verifica si una fila está completamente en blanco.
     */
    private boolean isRowBlank(Row row) {
        for (int i = 0; i < row.getLastCellNum(); i++) {
            Cell cell = row.getCell(i);
            if (cell != null && cell.getCellType() != CellType.BLANK) {
                String value = getCellValueAsString(cell);
                if (value != null && !value.trim().isEmpty()) {
                    return false;
                }
            }
        }
        return true;
    }
}
