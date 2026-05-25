package com.bolsadeideas.springboot.backend.apirest.models.services;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;

import java.util.*;

/**
 * Feature: admin-excel-leads-module, Property 2: Mapeo de columnas por similitud de texto
 *
 * Para cualquier encabezado de columna que sea una variación reconocible de un campo del Lead
 * (incluyendo sinónimos, variaciones de mayúsculas, guiones bajos vs espacios), el Motor de Mapeo
 * debe asociarlo correctamente al campo correspondiente del Lead.
 *
 * Validates: Requirements 2.1, 2.3
 */
class ColumnMappingEnginePropertyTest {

    private final ColumnMappingEngine engine = new ColumnMappingEngine();

    // Known synonyms for each field (matching the engine's FIELD_SYNONYMS)
    private static final Map<String, List<String>> FIELD_SYNONYMS = Map.of(
        "nombre", List.of("nombre", "name", "first_name", "firstname", "primer nombre", "nombres"),
        "apellido", List.of("apellido", "lastname", "last_name", "surname", "apellidos", "segundo nombre"),
        "lastCallStatus", List.of("last_call_status", "estado_llamada", "call_status", "status", "estado"),
        "pais", List.of("pais", "país", "country", "nacionalidad"),
        "telefono", List.of("telefono", "teléfono", "phone", "tel", "celular", "mobile", "número"),
        "email", List.of("email", "correo", "e-mail", "mail", "correo electrónico"),
        "campana", List.of("campaña", "campana", "campaign", "camp"),
        "fechaRegistro", List.of("fecha_registro", "fecha registro", "registration_date", "date", "fecha"),
        "comentarios", List.of("comentarios", "comments", "notas", "notes", "observaciones")
    );

    /**
     * **Validates: Requirements 2.1, 2.3**
     *
     * Property: When a single header is a known synonym (with case/format variations),
     * the engine must map it to the correct field.
     */
    @Property(tries = 150)
    void knownSynonymVariationsMustMapToCorrectField(
            @ForAll("headerVariations") HeaderVariation variation) {

        // Create a list with a single header
        List<String> headers = List.of(variation.header);

        MappingResult result = engine.mapColumns(headers);

        // The header should be mapped to the expected field
        String mappedField = result.getColumnMapping().get(0);
        assert mappedField != null :
            "Header '" + variation.header + "' (synonym of '" + variation.expectedField +
            "') was not mapped to any field";
        assert mappedField.equals(variation.expectedField) :
            "Header '" + variation.header + "' was mapped to '" + mappedField +
            "' but expected '" + variation.expectedField + "'";
    }

    /**
     * **Validates: Requirements 2.1, 2.3**
     *
     * Property: When multiple distinct field synonyms are provided as headers,
     * each one maps to its respective field without conflicts.
     */
    @Property(tries = 100)
    void multipleDistinctHeadersMustMapToTheirRespectiveFields(
            @ForAll("multipleHeaderSets") List<HeaderVariation> variations) {

        List<String> headers = new ArrayList<>();
        for (HeaderVariation v : variations) {
            headers.add(v.header);
        }

        MappingResult result = engine.mapColumns(headers);

        // Each header should map to its expected field
        for (int i = 0; i < variations.size(); i++) {
            HeaderVariation v = variations.get(i);
            String mappedField = result.getColumnMapping().get(i);
            assert mappedField != null :
                "Header '" + v.header + "' at index " + i + " (synonym of '" +
                v.expectedField + "') was not mapped";
            assert mappedField.equals(v.expectedField) :
                "Header '" + v.header + "' at index " + i + " was mapped to '" +
                mappedField + "' but expected '" + v.expectedField + "'";
        }
    }

    // --- Arbitraries / Providers ---

    @Provide
    Arbitrary<HeaderVariation> headerVariations() {
        // Pick a random field, then pick a random synonym, then apply a random transformation
        return Arbitraries.of(FIELD_SYNONYMS.keySet().toArray(new String[0]))
            .flatMap(field -> {
                List<String> synonyms = FIELD_SYNONYMS.get(field);
                return Arbitraries.of(synonyms)
                    .flatMap(synonym -> transformations()
                        .map(transformation -> new HeaderVariation(
                            applyTransformation(synonym, transformation), field)));
            });
    }

    @Provide
    Arbitrary<List<HeaderVariation>> multipleHeaderSets() {
        // Generate a subset of fields (2-5 distinct fields) with one variation each
        List<String> allFields = new ArrayList<>(FIELD_SYNONYMS.keySet());

        return Arbitraries.integers().between(2, 5).flatMap(count -> {
            // Shuffle and take first 'count' fields
            return Arbitraries.shuffle(allFields).map(shuffled -> shuffled.subList(0, count))
                .flatMap(selectedFields -> {
                    List<Arbitrary<HeaderVariation>> variationArbitraries = new ArrayList<>();
                    for (String field : selectedFields) {
                        List<String> synonyms = FIELD_SYNONYMS.get(field);
                        Arbitrary<HeaderVariation> va = Arbitraries.of(synonyms)
                            .flatMap(synonym -> transformations()
                                .map(transformation -> new HeaderVariation(
                                    applyTransformation(synonym, transformation), field)));
                        variationArbitraries.add(va);
                    }
                    return Combinators.combine(variationArbitraries).as(list -> list);
                });
        });
    }

    private Arbitrary<String> transformations() {
        return Arbitraries.of(
            "uppercase",
            "mixedCase",
            "withUnderscores",
            "withHyphens",
            "withExtraSpaces",
            "original"
        );
    }

    private String applyTransformation(String synonym, String transformation) {
        switch (transformation) {
            case "uppercase":
                return synonym.toUpperCase();
            case "mixedCase":
                return toMixedCase(synonym);
            case "withUnderscores":
                return synonym.replace(' ', '_');
            case "withHyphens":
                return synonym.replace(' ', '-');
            case "withExtraSpaces":
                return "  " + synonym + "  ";
            case "original":
            default:
                return synonym;
        }
    }

    private String toMixedCase(String input) {
        StringBuilder sb = new StringBuilder();
        for (int i = 0; i < input.length(); i++) {
            char c = input.charAt(i);
            if (i % 2 == 0) {
                sb.append(Character.toUpperCase(c));
            } else {
                sb.append(Character.toLowerCase(c));
            }
        }
        return sb.toString();
    }

    // Helper class to hold a header variation and its expected field
    static class HeaderVariation {
        final String header;
        final String expectedField;

        HeaderVariation(String header, String expectedField) {
            this.header = header;
            this.expectedField = expectedField;
        }

        @Override
        public String toString() {
            return "HeaderVariation{header='" + header + "', expectedField='" + expectedField + "'}";
        }
    }
}
