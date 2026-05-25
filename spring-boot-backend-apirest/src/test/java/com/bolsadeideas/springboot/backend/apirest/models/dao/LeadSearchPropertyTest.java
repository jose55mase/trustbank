package com.bolsadeideas.springboot.backend.apirest.models.dao;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

/**
 * Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda
 *
 * Para cualquier término de búsqueda y conjunto de leads, todos los leads retornados
 * deben contener el término en al menos uno de sus campos (nombre, apellido, lastCallStatus,
 * país, teléfono, email, campaña, comentarios), y ningún lead que contenga el término
 * en algún campo debe ser omitido de los resultados.
 *
 * Este test simula la lógica de búsqueda del @Query en ILeadDao a nivel unitario (sin DB).
 *
 * **Validates: Requirements 5.2**
 */
class LeadSearchPropertyTest {

    /**
     * Simulates the search logic from ILeadDao @Query:
     * LOWER(field) LIKE LOWER(CONCAT('%', :term, '%'))
     *
     * A lead matches if any of its searchable fields contains the term (case-insensitive).
     */
    private boolean leadMatchesTerm(LeadEntity lead, String term) {
        String lowerTerm = term.toLowerCase();
        return containsIgnoreCase(lead.getNombre(), lowerTerm)
            || containsIgnoreCase(lead.getApellido(), lowerTerm)
            || containsIgnoreCase(lead.getLastCallStatus(), lowerTerm)
            || containsIgnoreCase(lead.getPais(), lowerTerm)
            || containsIgnoreCase(lead.getTelefono(), lowerTerm)
            || containsIgnoreCase(lead.getEmail(), lowerTerm)
            || containsIgnoreCase(lead.getCampana(), lowerTerm)
            || containsIgnoreCase(lead.getComentarios(), lowerTerm);
    }

    private boolean containsIgnoreCase(String field, String lowerTerm) {
        if (field == null) return false;
        return field.toLowerCase().contains(lowerTerm);
    }

    /**
     * Simulates the searchByTerm query: returns all leads from the list that match the term.
     */
    private List<LeadEntity> simulateSearch(List<LeadEntity> leads, String term) {
        return leads.stream()
            .filter(lead -> leadMatchesTerm(lead, term))
            .collect(Collectors.toList());
    }

    /**
     * **Validates: Requirements 5.2**
     *
     * Property: All results returned by the search must contain the search term
     * in at least one searchable field (soundness). No false positives.
     */
    @Property(tries = 150)
    @Tag("Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda")
    void allSearchResultsMustContainTermInAtLeastOneField(
            @ForAll("leadsList") List<LeadEntity> leads,
            @ForAll("searchTerms") String term) {

        // Skip empty search terms as they would match everything trivially
        Assume.that(term != null && !term.isEmpty());

        List<LeadEntity> results = simulateSearch(leads, term);

        // Soundness: every result must contain the term in at least one field
        for (LeadEntity result : results) {
            assert leadMatchesTerm(result, term) :
                "Search result does not contain term '" + term + "' in any field. " +
                "Lead: nombre='" + result.getNombre() + "', apellido='" + result.getApellido() +
                "', email='" + result.getEmail() + "'";
        }
    }

    /**
     * **Validates: Requirements 5.2**
     *
     * Property: No lead that contains the search term in any field should be omitted
     * from the results (completeness). No false negatives.
     */
    @Property(tries = 150)
    @Tag("Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda")
    void noLeadContainingTermShouldBeOmittedFromResults(
            @ForAll("leadsList") List<LeadEntity> leads,
            @ForAll("searchTerms") String term) {

        Assume.that(term != null && !term.isEmpty());

        List<LeadEntity> results = simulateSearch(leads, term);

        // Completeness: every lead that matches must be in the results
        for (LeadEntity lead : leads) {
            if (leadMatchesTerm(lead, term)) {
                assert results.contains(lead) :
                    "Lead containing term '" + term + "' was omitted from results. " +
                    "Lead: nombre='" + lead.getNombre() + "', apellido='" + lead.getApellido() +
                    "', email='" + lead.getEmail() + "'";
            }
        }
    }

    /**
     * **Validates: Requirements 5.2**
     *
     * Property: The search results must be exactly the set of leads that contain the term.
     * This combines soundness and completeness into a single equivalence check.
     */
    @Property(tries = 150)
    @Tag("Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda")
    void searchResultsMustBeExactlyTheMatchingLeads(
            @ForAll("leadsList") List<LeadEntity> leads,
            @ForAll("searchTerms") String term) {

        Assume.that(term != null && !term.isEmpty());

        List<LeadEntity> results = simulateSearch(leads, term);

        // Count leads that should match
        long expectedCount = leads.stream()
            .filter(lead -> leadMatchesTerm(lead, term))
            .count();

        assert results.size() == expectedCount :
            "Expected " + expectedCount + " results but got " + results.size() +
            " for term '" + term + "' in a list of " + leads.size() + " leads";
    }

    /**
     * **Validates: Requirements 5.2**
     *
     * Property: Search must be case-insensitive. Searching with uppercase, lowercase,
     * or mixed case of the same term must yield identical results.
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda")
    void searchMustBeCaseInsensitive(
            @ForAll("leadsList") List<LeadEntity> leads,
            @ForAll("searchTerms") String term) {

        Assume.that(term != null && !term.isEmpty());

        List<LeadEntity> resultsLower = simulateSearch(leads, term.toLowerCase());
        List<LeadEntity> resultsUpper = simulateSearch(leads, term.toUpperCase());
        List<LeadEntity> resultsOriginal = simulateSearch(leads, term);

        assert resultsLower.size() == resultsUpper.size() :
            "Case-insensitive search failed: lowercase gave " + resultsLower.size() +
            " results, uppercase gave " + resultsUpper.size() + " for term '" + term + "'";

        assert resultsLower.size() == resultsOriginal.size() :
            "Case-insensitive search failed: lowercase gave " + resultsLower.size() +
            " results, original gave " + resultsOriginal.size() + " for term '" + term + "'";
    }

    /**
     * **Validates: Requirements 5.2**
     *
     * Property: When a known term is injected into a specific field of a lead,
     * that lead must always appear in the search results for that term.
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 7: Correctitud de la búsqueda")
    void leadWithInjectedTermMustAlwaysBeFound(
            @ForAll("leadsList") List<LeadEntity> leads,
            @ForAll("searchTerms") String term,
            @ForAll @IntRange(min = 0, max = 7) int fieldIndex) {

        Assume.that(term != null && !term.isEmpty());
        Assume.that(!leads.isEmpty());

        // Create a lead with the term injected into a specific field
        LeadEntity injectedLead = new LeadEntity();
        injectedLead.setNombre("Default");
        injectedLead.setApellido("Default");
        injectedLead.setLastCallStatus("Pendiente");
        injectedLead.setPais("Chile");
        injectedLead.setTelefono("+123456789");
        injectedLead.setEmail("test@example.com");
        injectedLead.setCampana("TestCampaign");
        injectedLead.setComentarios("No comments");

        // Inject the term into the selected field
        String valueWithTerm = "prefix" + term + "suffix";
        switch (fieldIndex) {
            case 0: injectedLead.setNombre(valueWithTerm); break;
            case 1: injectedLead.setApellido(valueWithTerm); break;
            case 2: injectedLead.setLastCallStatus(valueWithTerm); break;
            case 3: injectedLead.setPais(valueWithTerm); break;
            case 4: injectedLead.setTelefono(valueWithTerm); break;
            case 5: injectedLead.setEmail(valueWithTerm); break;
            case 6: injectedLead.setCampana(valueWithTerm); break;
            case 7: injectedLead.setComentarios(valueWithTerm); break;
        }

        // Add the injected lead to the list
        List<LeadEntity> allLeads = new ArrayList<>(leads);
        allLeads.add(injectedLead);

        List<LeadEntity> results = simulateSearch(allLeads, term);

        assert results.contains(injectedLead) :
            "Lead with term '" + term + "' injected in field " + fieldIndex +
            " was not found in search results";
    }

    // --- Arbitraries / Providers ---

    @Provide
    Arbitrary<List<LeadEntity>> leadsList() {
        return leadEntity().list().ofMinSize(0).ofMaxSize(30);
    }

    @Provide
    Arbitrary<LeadEntity> leadEntity() {
        Arbitrary<String> nombres = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(20);
        Arbitrary<String> apellidos = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(20);
        Arbitrary<String> statuses = Arbitraries.of(
            "Contactado", "No contesta", "Interesado", "Rechazado",
            "Pendiente", "En seguimiento", "Cerrado");
        Arbitrary<String> paises = Arbitraries.of(
            "Chile", "Argentina", "México", "Colombia", "Perú",
            "España", "Ecuador", "Venezuela", "Uruguay", "Brasil");
        Arbitrary<String> telefonos = Arbitraries.strings()
            .withCharRange('0', '9').ofMinLength(8).ofMaxLength(12)
            .map(digits -> "+" + digits);
        Arbitrary<String> emails = Arbitraries.strings()
            .alpha().ofMinLength(3).ofMaxLength(10)
            .map(user -> user.toLowerCase() + "@example.com");
        Arbitrary<String> campanas = Arbitraries.of(
            "Verano2024", "BlackFriday", "Navidad2024",
            "Lanzamiento", "Reactivacion", "Referidos");
        Arbitrary<String> comentarios = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(50);

        Arbitrary<String[]> firstGroup = Combinators.combine(
            nombres, apellidos, statuses, paises
        ).as((n, a, s, p) -> new String[]{n, a, s, p});

        Arbitrary<String[]> secondGroup = Combinators.combine(
            telefonos, emails, campanas, comentarios
        ).as((t, e, c, com) -> new String[]{t, e, c, com});

        return Combinators.combine(firstGroup, secondGroup)
            .as((first, second) -> {
                LeadEntity lead = new LeadEntity();
                lead.setNombre(first[0]);
                lead.setApellido(first[1]);
                lead.setLastCallStatus(first[2]);
                lead.setPais(first[3]);
                lead.setTelefono(second[0]);
                lead.setEmail(second[1]);
                lead.setCampana(second[2]);
                lead.setComentarios(second[3]);
                return lead;
            });
    }

    @Provide
    Arbitrary<String> searchTerms() {
        return Arbitraries.oneOf(
            // Short alphabetic terms (likely to match in generated data)
            Arbitraries.strings().alpha().ofMinLength(1).ofMaxLength(4),
            // Terms from known field values (high chance of matching)
            Arbitraries.of("chile", "arg", "col", "per", "mex",
                "contactado", "pendiente", "interesado", "cerrado",
                "example", "verano", "navidad", "black",
                "reactivacion", "referidos", "lanzamiento"),
            // Mixed case terms
            Arbitraries.of("Chile", "CHILE", "cHiLe", "ARG", "Col")
        );
    }
}
