package com.bolsadeideas.springboot.backend.apirest.models.services;

import net.jqwik.api.*;

import org.apache.poi.ss.usermodel.*;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.mock.web.MockMultipartFile;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.*;

/**
 * Feature: admin-excel-leads-module, Property 3: Procesamiento de importación con tolerancia a errores
 *
 * Para cualquier archivo Excel con N filas donde M son válidas y (N-M) son inválidas,
 * el sistema debe crear exactamente M registros de Lead y reportar exactamente (N-M) errores,
 * sin que las filas inválidas afecten el procesamiento de las válidas.
 *
 * Validates: Requirements 3.1, 3.3
 */
class ExcelParserImportPropertyTest {

    private final ExcelParserService parserService = new ExcelParserService();

    // Standard column mapping: column index -> field name
    private static final Map<Integer, String> STANDARD_MAPPING;
    static {
        Map<Integer, String> map = new HashMap<>();
        map.put(0, "nombre");
        map.put(1, "apellido");
        map.put(2, "email");
        map.put(3, "telefono");
        map.put(4, "pais");
        map.put(5, "campana");
        map.put(6, "lastCallStatus");
        map.put(7, "comentarios");
        STANDARD_MAPPING = Collections.unmodifiableMap(map);
    }

    /**
     * **Validates: Requirements 3.1, 3.3**
     *
     * Property: For any Excel file with a mix of valid and invalid rows,
     * the total number of valid leads + errors must equal the total number of
     * non-blank data rows processed. This ensures no rows are silently lost.
     */
    @Property(tries = 25)
    void validLeadsPlusErrorsMustEqualTotalNonBlankDataRows(
            @ForAll("excelRowMixes") RowMix rowMix) throws IOException {

        // Create an Excel file in memory with the given mix of rows
        byte[] excelBytes = createExcelFile(rowMix);

        MockMultipartFile file = new MockMultipartFile(
            "file", "test_leads.xlsx",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.officedocument",
            excelBytes
        );

        // Parse the rows using the service
        ParseResult result = parserService.parseRows(file, STANDARD_MAPPING);

        int totalDataRows = rowMix.validRows.size() + rowMix.invalidRows.size();
        int totalProcessed = result.getValidLeads().size() + result.getErrors().size();

        // Property: validLeads + errors == total non-blank data rows
        assert totalProcessed == totalDataRows :
            "Expected total processed (" + totalProcessed + ") to equal total data rows (" +
            totalDataRows + "). Valid leads: " + result.getValidLeads().size() +
            ", Errors: " + result.getErrors().size() +
            ", Valid input rows: " + rowMix.validRows.size() +
            ", Invalid input rows: " + rowMix.invalidRows.size();
    }

    /**
     * **Validates: Requirements 3.1, 3.3**
     *
     * Property: Valid rows (with at least nombre or email) must always produce
     * LeadEntity objects, regardless of the presence of invalid rows in the same file.
     * Invalid rows must not prevent valid rows from being processed.
     */
    @Property(tries = 25)
    void validRowsMustProduceLeadEntitiesRegardlessOfInvalidRows(
            @ForAll("excelRowMixes") RowMix rowMix) throws IOException {

        byte[] excelBytes = createExcelFile(rowMix);

        MockMultipartFile file = new MockMultipartFile(
            "file", "test_leads.xlsx",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.officedocument",
            excelBytes
        );

        ParseResult result = parserService.parseRows(file, STANDARD_MAPPING);

        // Valid rows should always produce valid leads
        assert result.getValidLeads().size() == rowMix.validRows.size() :
            "Expected " + rowMix.validRows.size() + " valid leads but got " +
            result.getValidLeads().size() + ". Errors: " + result.getErrors();

        // Each valid lead must have nombre or email set (the minimum required data)
        for (int i = 0; i < result.getValidLeads().size(); i++) {
            var lead = result.getValidLeads().get(i);
            boolean hasNombre = lead.getNombre() != null && !lead.getNombre().trim().isEmpty();
            boolean hasEmail = lead.getEmail() != null && !lead.getEmail().trim().isEmpty();
            assert hasNombre || hasEmail :
                "Valid lead at index " + i + " should have nombre or email set";
        }
    }

    /**
     * **Validates: Requirements 3.1, 3.3**
     *
     * Property: Invalid rows (missing both nombre and email) must produce error messages
     * and must not prevent subsequent valid rows from being processed correctly.
     */
    @Property(tries = 25)
    void invalidRowsMustProduceErrorsWithoutAffectingValidRows(
            @ForAll("excelRowMixes") RowMix rowMix) throws IOException {

        byte[] excelBytes = createExcelFile(rowMix);

        MockMultipartFile file = new MockMultipartFile(
            "file", "test_leads.xlsx",
            "application/vnd.openxmlformats-officedocument.spreadsheetml.officedocument",
            excelBytes
        );

        ParseResult result = parserService.parseRows(file, STANDARD_MAPPING);

        // Errors must equal the number of invalid rows
        assert result.getErrors().size() == rowMix.invalidRows.size() :
            "Expected " + rowMix.invalidRows.size() + " errors but got " +
            result.getErrors().size() + ". Errors: " + result.getErrors();

        // Each error message should reference a row number
        for (String error : result.getErrors()) {
            assert error.contains("Fila") :
                "Error message should reference a row number: " + error;
        }
    }

    // --- Arbitraries / Providers ---

    @Provide
    Arbitrary<RowMix> excelRowMixes() {
        Arbitrary<List<ValidRowData>> validRows = validRowDataArbitrary()
            .list().ofMinSize(1).ofMaxSize(8);

        Arbitrary<List<InvalidRowData>> invalidRows = invalidRowDataArbitrary()
            .list().ofMinSize(1).ofMaxSize(5);

        return Combinators.combine(validRows, invalidRows)
            .as((valid, invalid) -> new RowMix(valid, invalid));
    }

    private Arbitrary<ValidRowData> validRowDataArbitrary() {
        // Valid rows MUST have at least nombre or email (non-empty)
        return Combinators.combine(
            Arbitraries.strings().alpha().ofMinLength(2).ofMaxLength(15), // nombre (always present)
            Arbitraries.strings().alpha().ofMinLength(2).ofMaxLength(15), // apellido
            emailArbitrary(),                                              // email
            phoneArbitrary(),                                              // telefono
            Arbitraries.of("México", "Colombia", "Argentina", "España", "Chile", "Perú"), // pais
            Arbitraries.of("Campaña A", "Campaña B", "Campaña C", "Ventas", "Marketing"), // campana
            Arbitraries.of("Contactado", "No contesta", "Interesado", "Rechazado"),       // lastCallStatus
            Arbitraries.strings().alpha().ofMinLength(0).ofMaxLength(50)   // comentarios
        ).as(ValidRowData::new);
    }

    private Arbitrary<InvalidRowData> invalidRowDataArbitrary() {
        // Invalid rows have NO nombre AND NO email - only other fields
        // This triggers the validation error in parseRowToLead
        return Combinators.combine(
            Arbitraries.of("", "Colombia", "Argentina", "España"),  // pais (non-empty to avoid blank row)
            Arbitraries.strings().alpha().ofMinLength(0).ofMaxLength(10), // apellido
            phoneArbitrary()                                               // telefono
        ).as(InvalidRowData::new);
    }

    private Arbitrary<String> emailArbitrary() {
        return Combinators.combine(
            Arbitraries.strings().alpha().ofMinLength(3).ofMaxLength(8),
            Arbitraries.of("gmail.com", "hotmail.com", "empresa.mx", "correo.co")
        ).as((user, domain) -> user.toLowerCase() + "@" + domain);
    }

    private Arbitrary<String> phoneArbitrary() {
        return Arbitraries.strings().numeric().ofMinLength(8).ofMaxLength(12)
            .map(digits -> "+" + digits);
    }

    // --- Helper Methods ---

    /**
     * Creates an Excel file in memory with the given mix of valid and invalid rows.
     * The rows are interleaved to ensure invalid rows don't block valid ones.
     */
    private byte[] createExcelFile(RowMix rowMix) throws IOException {
        try (Workbook workbook = new XSSFWorkbook();
             ByteArrayOutputStream baos = new ByteArrayOutputStream()) {

            Sheet sheet = workbook.createSheet("Leads");

            // Create header row
            Row headerRow = sheet.createRow(0);
            headerRow.createCell(0).setCellValue("nombre");
            headerRow.createCell(1).setCellValue("apellido");
            headerRow.createCell(2).setCellValue("email");
            headerRow.createCell(3).setCellValue("telefono");
            headerRow.createCell(4).setCellValue("pais");
            headerRow.createCell(5).setCellValue("campana");
            headerRow.createCell(6).setCellValue("lastCallStatus");
            headerRow.createCell(7).setCellValue("comentarios");

            // Interleave valid and invalid rows to verify ordering doesn't matter
            int rowIndex = 1;
            int validIdx = 0;
            int invalidIdx = 0;

            while (validIdx < rowMix.validRows.size() || invalidIdx < rowMix.invalidRows.size()) {
                if (validIdx < rowMix.validRows.size()) {
                    createValidRow(sheet, rowIndex++, rowMix.validRows.get(validIdx));
                    validIdx++;
                }
                if (invalidIdx < rowMix.invalidRows.size()) {
                    createInvalidRow(sheet, rowIndex++, rowMix.invalidRows.get(invalidIdx));
                    invalidIdx++;
                }
            }

            workbook.write(baos);
            return baos.toByteArray();
        }
    }

    private void createValidRow(Sheet sheet, int rowIndex, ValidRowData data) {
        Row row = sheet.createRow(rowIndex);
        row.createCell(0).setCellValue(data.nombre);     // nombre - always non-empty
        row.createCell(1).setCellValue(data.apellido);
        row.createCell(2).setCellValue(data.email);      // email - always valid
        row.createCell(3).setCellValue(data.telefono);
        row.createCell(4).setCellValue(data.pais);
        row.createCell(5).setCellValue(data.campana);
        row.createCell(6).setCellValue(data.lastCallStatus);
        row.createCell(7).setCellValue(data.comentarios);
    }

    private void createInvalidRow(Sheet sheet, int rowIndex, InvalidRowData data) {
        Row row = sheet.createRow(rowIndex);
        // nombre (index 0) is left EMPTY - no cell created or empty string
        row.createCell(0).setCellValue("");  // empty nombre
        row.createCell(1).setCellValue(data.apellido);
        row.createCell(2).setCellValue("");  // empty email
        row.createCell(3).setCellValue(data.telefono);
        row.createCell(4).setCellValue(data.pais);  // non-empty to avoid being treated as blank
        row.createCell(5).setCellValue("");
        row.createCell(6).setCellValue("");
        row.createCell(7).setCellValue("");
    }

    // --- Data Classes ---

    static class RowMix {
        final List<ValidRowData> validRows;
        final List<InvalidRowData> invalidRows;

        RowMix(List<ValidRowData> validRows, List<InvalidRowData> invalidRows) {
            this.validRows = validRows;
            this.invalidRows = invalidRows;
        }

        @Override
        public String toString() {
            return "RowMix{validRows=" + validRows.size() + ", invalidRows=" + invalidRows.size() + "}";
        }
    }

    static class ValidRowData {
        final String nombre;
        final String apellido;
        final String email;
        final String telefono;
        final String pais;
        final String campana;
        final String lastCallStatus;
        final String comentarios;

        ValidRowData(String nombre, String apellido, String email, String telefono,
                     String pais, String campana, String lastCallStatus, String comentarios) {
            this.nombre = nombre;
            this.apellido = apellido;
            this.email = email;
            this.telefono = telefono;
            this.pais = pais;
            this.campana = campana;
            this.lastCallStatus = lastCallStatus;
            this.comentarios = comentarios;
        }
    }

    static class InvalidRowData {
        final String pais;
        final String apellido;
        final String telefono;

        InvalidRowData(String pais, String apellido, String telefono) {
            this.pais = pais;
            this.apellido = apellido;
            this.telefono = telefono;
        }
    }
}
