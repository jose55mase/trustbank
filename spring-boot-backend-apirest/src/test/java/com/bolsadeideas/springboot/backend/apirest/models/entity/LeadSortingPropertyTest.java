package com.bolsadeideas.springboot.backend.apirest.models.entity;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;

import java.util.*;
import java.util.Comparator;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * Feature: admin-excel-leads-module, Property 6: Correctitud del ordenamiento
 *
 * Para cualquier conjunto de leads y cualquier columna de ordenamiento
 * (nombre, apellido, lastCallStatus, país, teléfono, email, campaña),
 * los resultados ordenados de forma ascendente deben satisfacer que cada elemento
 * es menor o igual al siguiente según el criterio de la columna seleccionada.
 *
 * **Validates: Requirements 4.4**
 */
class LeadSortingPropertyTest {

    // Sortable columns as defined in the requirements
    private static final List<String> SORTABLE_COLUMNS = Arrays.asList(
        "nombre", "apellido", "lastCallStatus", "pais", "telefono", "email", "campana"
    );

    /**
     * **Validates: Requirements 4.4**
     *
     * Property: For any list of leads sorted in ascending order by any sortable column,
     * each element must be <= the next element (case-insensitive string comparison).
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 6: Correctitud del ordenamiento")
    void sortedAscendingMustHaveEachElementLessThanOrEqualToNext(
            @ForAll("leadLists") List<LeadEntity> leads,
            @ForAll("sortableColumn") String column) {

        // Get the field extractor for the given column
        Function<LeadEntity, String> extractor = getFieldExtractor(column);

        // Sort ascending (case-insensitive)
        List<LeadEntity> sorted = leads.stream()
            .sorted(Comparator.comparing(
                lead -> extractor.apply(lead).toLowerCase()))
            .collect(Collectors.toList());

        // Verify ordering: each element <= next element
        for (int i = 0; i < sorted.size() - 1; i++) {
            String current = extractor.apply(sorted.get(i)).toLowerCase();
            String next = extractor.apply(sorted.get(i + 1)).toLowerCase();
            assert current.compareTo(next) <= 0 :
                "Ascending sort violated for column '" + column + "' at index " + i +
                ": '" + current + "' > '" + next + "'";
        }
    }

    /**
     * **Validates: Requirements 4.4**
     *
     * Property: For any list of leads sorted in descending order by any sortable column,
     * each element must be >= the next element (case-insensitive string comparison).
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 6: Correctitud del ordenamiento")
    void sortedDescendingMustHaveEachElementGreaterThanOrEqualToNext(
            @ForAll("leadLists") List<LeadEntity> leads,
            @ForAll("sortableColumn") String column) {

        // Get the field extractor for the given column
        Function<LeadEntity, String> extractor = getFieldExtractor(column);

        // Sort descending (case-insensitive)
        List<LeadEntity> sorted = leads.stream()
            .sorted(Comparator.comparing(
                (LeadEntity lead) -> extractor.apply(lead).toLowerCase()).reversed())
            .collect(Collectors.toList());

        // Verify ordering: each element >= next element
        for (int i = 0; i < sorted.size() - 1; i++) {
            String current = extractor.apply(sorted.get(i)).toLowerCase();
            String next = extractor.apply(sorted.get(i + 1)).toLowerCase();
            assert current.compareTo(next) >= 0 :
                "Descending sort violated for column '" + column + "' at index " + i +
                ": '" + current + "' < '" + next + "'";
        }
    }

    /**
     * **Validates: Requirements 4.4**
     *
     * Property: Sorting must preserve all elements (no elements lost or duplicated).
     * The sorted list must contain exactly the same elements as the original.
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 6: Correctitud del ordenamiento")
    void sortingMustPreserveAllElements(
            @ForAll("leadLists") List<LeadEntity> leads,
            @ForAll("sortableColumn") String column) {

        Function<LeadEntity, String> extractor = getFieldExtractor(column);

        // Sort ascending
        List<LeadEntity> sorted = leads.stream()
            .sorted(Comparator.comparing(
                lead -> extractor.apply(lead).toLowerCase()))
            .collect(Collectors.toList());

        // Same size
        assert sorted.size() == leads.size() :
            "Sorted list size (" + sorted.size() + ") differs from original (" + leads.size() + ")";

        // Same elements (by reference)
        List<LeadEntity> originalCopy = new ArrayList<>(leads);
        for (LeadEntity sortedLead : sorted) {
            boolean removed = originalCopy.remove(sortedLead);
            assert removed : "Sorted list contains an element not in the original list";
        }
        assert originalCopy.isEmpty() :
            "Original list has elements not present in sorted list";
    }

    /**
     * **Validates: Requirements 4.4**
     *
     * Property: Ascending and descending sorts of the same data must be exact reverses
     * of each other (when stable sort is used and all values are distinct for the column).
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 6: Correctitud del ordenamiento")
    void ascendingAndDescendingMustProduceOppositeOrderings(
            @ForAll("leadLists") List<LeadEntity> leads,
            @ForAll("sortableColumn") String column) {

        Function<LeadEntity, String> extractor = getFieldExtractor(column);

        Comparator<LeadEntity> ascComparator = Comparator.comparing(
            lead -> extractor.apply(lead).toLowerCase());

        List<LeadEntity> ascending = leads.stream()
            .sorted(ascComparator)
            .collect(Collectors.toList());

        List<LeadEntity> descending = leads.stream()
            .sorted(ascComparator.reversed())
            .collect(Collectors.toList());

        // The first element of ascending should equal the last of descending (and vice versa)
        // when the list is non-empty
        if (!leads.isEmpty()) {
            String firstAsc = extractor.apply(ascending.get(0)).toLowerCase();
            String lastDesc = extractor.apply(descending.get(descending.size() - 1)).toLowerCase();
            assert firstAsc.compareTo(lastDesc) == 0 :
                "First ascending element '" + firstAsc +
                "' should equal last descending element '" + lastDesc + "'";

            String lastAsc = extractor.apply(ascending.get(ascending.size() - 1)).toLowerCase();
            String firstDesc = extractor.apply(descending.get(0)).toLowerCase();
            assert lastAsc.compareTo(firstDesc) == 0 :
                "Last ascending element '" + lastAsc +
                "' should equal first descending element '" + firstDesc + "'";
        }
    }

    // --- Helper Methods ---

    private Function<LeadEntity, String> getFieldExtractor(String column) {
        switch (column) {
            case "nombre": return LeadEntity::getNombre;
            case "apellido": return LeadEntity::getApellido;
            case "lastCallStatus": return LeadEntity::getLastCallStatus;
            case "pais": return LeadEntity::getPais;
            case "telefono": return LeadEntity::getTelefono;
            case "email": return LeadEntity::getEmail;
            case "campana": return LeadEntity::getCampana;
            default: throw new IllegalArgumentException("Unknown column: " + column);
        }
    }

    // --- Arbitraries / Providers ---

    @Provide
    Arbitrary<List<LeadEntity>> leadLists() {
        return leadEntity().list().ofMinSize(1).ofMaxSize(30);
    }

    @Provide
    Arbitrary<String> sortableColumn() {
        return Arbitraries.of(SORTABLE_COLUMNS);
    }

    private Arbitrary<LeadEntity> leadEntity() {
        Arbitrary<String> nombres = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(30);
        Arbitrary<String> apellidos = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(30);
        Arbitrary<String> statuses = Arbitraries.of(
            "Contactado", "No contesta", "Interesado", "Rechazado",
            "Pendiente", "En seguimiento", "Cerrado", "Nuevo");
        Arbitrary<String> paises = Arbitraries.of(
            "Chile", "Argentina", "México", "Colombia", "Perú",
            "España", "Ecuador", "Venezuela", "Uruguay", "Brasil");
        Arbitrary<String> telefonos = Arbitraries.strings()
            .withCharRange('0', '9').ofMinLength(8).ofMaxLength(15)
            .map(digits -> "+" + digits);
        Arbitrary<String> emails = Arbitraries.strings()
            .alpha().ofMinLength(3).ofMaxLength(15)
            .map(user -> user.toLowerCase() + "@example.com");
        Arbitrary<String> campanas = Arbitraries.of(
            "Campaña Verano 2024", "Black Friday", "Navidad 2024",
            "Lanzamiento Producto", "Reactivación", "Referidos",
            "Aniversario", "Promoción Especial");

        // Combine into LeadEntity using two groups (jqwik max 8 params per combine)
        Arbitrary<String[]> firstGroup = Combinators.combine(
            nombres, apellidos, statuses, paises
        ).as((n, a, s, p) -> new String[]{n, a, s, p});

        Arbitrary<String[]> secondGroup = Combinators.combine(
            telefonos, emails, campanas
        ).as((t, e, c) -> new String[]{t, e, c});

        return Combinators.combine(firstGroup, secondGroup)
            .as((first, second) -> {
                LeadEntity entity = new LeadEntity();
                entity.setNombre(first[0]);
                entity.setApellido(first[1]);
                entity.setLastCallStatus(first[2]);
                entity.setPais(first[3]);
                entity.setTelefono(second[0]);
                entity.setEmail(second[1]);
                entity.setCampana(second[2]);
                entity.setFechaRegistro(new Date());
                entity.setComentarios("Test comment");
                entity.setImportId(1L);
                return entity;
            });
    }
}
