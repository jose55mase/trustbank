package com.bolsadeideas.springboot.backend.apirest.models.services;

/**
 * Respuesta con el resultado de la importación de leads desde un archivo Excel.
 * Incluye contadores de éxito, errores, duplicados, total de filas y el ID de la importación.
 */
public class ImportResultResponse {

    private int successCount;
    private int errorCount;
    private int duplicateCount;
    private int totalRows;
    private Long importId;

    public ImportResultResponse() {
    }

    public ImportResultResponse(int successCount, int errorCount, int duplicateCount, int totalRows, Long importId) {
        this.successCount = successCount;
        this.errorCount = errorCount;
        this.duplicateCount = duplicateCount;
        this.totalRows = totalRows;
        this.importId = importId;
    }

    public int getSuccessCount() {
        return successCount;
    }

    public void setSuccessCount(int successCount) {
        this.successCount = successCount;
    }

    public int getErrorCount() {
        return errorCount;
    }

    public void setErrorCount(int errorCount) {
        this.errorCount = errorCount;
    }

    public int getDuplicateCount() {
        return duplicateCount;
    }

    public void setDuplicateCount(int duplicateCount) {
        this.duplicateCount = duplicateCount;
    }

    public int getTotalRows() {
        return totalRows;
    }

    public void setTotalRows(int totalRows) {
        this.totalRows = totalRows;
    }

    public Long getImportId() {
        return importId;
    }

    public void setImportId(Long importId) {
        this.importId = importId;
    }
}
