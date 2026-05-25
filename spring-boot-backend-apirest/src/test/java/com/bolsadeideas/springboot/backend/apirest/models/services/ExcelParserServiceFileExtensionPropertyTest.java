package com.bolsadeideas.springboot.backend.apirest.models.services;

import net.jqwik.api.*;

/**
 * Feature: admin-excel-leads-module, Property 1: Validación de extensión de archivo
 *
 * Para cualquier nombre de archivo, el sistema debe aceptar el archivo si y solo si
 * su extensión es .xlsx o .xls (sin importar mayúsculas/minúsculas).
 * Cualquier otra extensión debe ser rechazada.
 *
 * **Validates: Requirements 1.4**
 */
class ExcelParserServiceFileExtensionPropertyTest {

    private final ExcelParserService excelParserService = new ExcelParserService();

    // ========== Property: Valid extensions are always accepted ==========

    @Property(tries = 100)
    @Label("Archivos con extensión .xlsx o .xls (case-insensitive) son aceptados")
    void validExtensionsAreAccepted(@ForAll("validExcelFileNames") String fileName) {
        // Should NOT throw any exception for valid Excel extensions
        try {
            excelParserService.validateFileExtension(fileName);
        } catch (Exception e) {
            throw new AssertionError("Expected no exception for valid file '" + fileName + "' but got: " + e.getMessage());
        }
    }

    // ========== Property: Invalid extensions are always rejected ==========

    @Property(tries = 100)
    @Label("Archivos con extensiones inválidas son rechazados con IllegalArgumentException")
    void invalidExtensionsAreRejected(@ForAll("invalidExcelFileNames") String fileName) {
        // Should throw IllegalArgumentException for invalid extensions
        try {
            excelParserService.validateFileExtension(fileName);
            throw new AssertionError("Expected IllegalArgumentException for invalid file '" + fileName + "' but no exception was thrown");
        } catch (IllegalArgumentException e) {
            // Expected
        }
    }

    // ========== Providers ==========

    @Provide
    Arbitrary<String> validExcelFileNames() {
        Arbitrary<String> baseNames = Arbitraries.strings()
                .alpha()
                .ofMinLength(1)
                .ofMaxLength(50);

        Arbitrary<String> validExtensions = Arbitraries.of(
                ".xlsx", ".xls",
                ".XLSX", ".XLS",
                ".Xlsx", ".Xls",
                ".xLsX", ".xLs",
                ".XLSX", ".XLS",
                ".XlSx", ".XlS"
        );

        return Combinators.combine(baseNames, validExtensions)
                .as((base, ext) -> base + ext);
    }

    @Provide
    Arbitrary<String> invalidExcelFileNames() {
        Arbitrary<String> baseNames = Arbitraries.strings()
                .alpha()
                .ofMinLength(1)
                .ofMaxLength(50);

        Arbitrary<String> invalidExtensions = Arbitraries.of(
                ".pdf", ".csv", ".doc", ".docx", ".txt",
                ".png", ".jpg", ".gif", ".html", ".xml",
                ".json", ".zip", ".rar", ".exe", ".bat",
                ".pptx", ".odt", ".rtf", ".xlsm", ".xlsb"
        );

        return Combinators.combine(baseNames, invalidExtensions)
                .as((base, ext) -> base + ext);
    }
}
