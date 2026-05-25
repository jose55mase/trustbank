package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.Map;

/**
 * Resultado del mapeo automático de columnas del Excel a campos del Lead.
 */
public class MappingResult {

    private Map<Integer, String> columnMapping; // índice de columna -> nombre del campo (null si no mapeado)
    private boolean hasUnmappedColumns;

    public MappingResult() {
    }

    public MappingResult(Map<Integer, String> columnMapping, boolean hasUnmappedColumns) {
        this.columnMapping = columnMapping;
        this.hasUnmappedColumns = hasUnmappedColumns;
    }

    public Map<Integer, String> getColumnMapping() {
        return columnMapping;
    }

    public void setColumnMapping(Map<Integer, String> columnMapping) {
        this.columnMapping = columnMapping;
    }

    public boolean isHasUnmappedColumns() {
        return hasUnmappedColumns;
    }

    public void setHasUnmappedColumns(boolean hasUnmappedColumns) {
        this.hasUnmappedColumns = hasUnmappedColumns;
    }
}
