package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.List;
import java.util.Map;

/**
 * Respuesta con la vista previa del mapeo de columnas del Excel.
 * Incluye los encabezados originales, el mapeo detectado, filas de preview y si hay columnas sin mapear.
 */
public class MappingPreviewResponse {

    private List<String> headers;
    private Map<Integer, String> columnMapping;
    private List<List<String>> previewRows;
    private boolean hasUnmappedColumns;

    public MappingPreviewResponse() {
    }

    public MappingPreviewResponse(List<String> headers, Map<Integer, String> columnMapping,
                                   List<List<String>> previewRows, boolean hasUnmappedColumns) {
        this.headers = headers;
        this.columnMapping = columnMapping;
        this.previewRows = previewRows;
        this.hasUnmappedColumns = hasUnmappedColumns;
    }

    public List<String> getHeaders() {
        return headers;
    }

    public void setHeaders(List<String> headers) {
        this.headers = headers;
    }

    public Map<Integer, String> getColumnMapping() {
        return columnMapping;
    }

    public void setColumnMapping(Map<Integer, String> columnMapping) {
        this.columnMapping = columnMapping;
    }

    public List<List<String>> getPreviewRows() {
        return previewRows;
    }

    public void setPreviewRows(List<List<String>> previewRows) {
        this.previewRows = previewRows;
    }

    public boolean isHasUnmappedColumns() {
        return hasUnmappedColumns;
    }

    public void setHasUnmappedColumns(boolean hasUnmappedColumns) {
        this.hasUnmappedColumns = hasUnmappedColumns;
    }
}
