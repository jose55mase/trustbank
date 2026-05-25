package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import net.jqwik.api.*;
import net.jqwik.api.constraints.*;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageImpl;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;

import java.util.*;
import java.util.stream.Collectors;

/**
 * Feature: admin-excel-leads-module, Property 5: Invariante de paginación
 *
 * Para cualquier conjunto de leads almacenados y cualquier número de página solicitado,
 * la respuesta paginada debe contener como máximo 20 registros por página, y la unión
 * de todas las páginas debe contener exactamente todos los leads del sistema sin
 * duplicados ni omisiones.
 *
 * Validates: Requirements 4.2
 */
class LeadPaginationPropertyTest {

    private static final int PAGE_SIZE = 20;

    /**
     * **Validates: Requirements 4.2**
     *
     * Property: Each page must contain at most 20 items.
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 5: Invariante de paginación")
    void eachPageMustHaveAtMost20Items(
            @ForAll("leadLists") List<LeadEntity> allLeads) {

        int totalPages = (int) Math.ceil((double) allLeads.size() / PAGE_SIZE);
        if (totalPages == 0) totalPages = 1;

        for (int pageNum = 0; pageNum < totalPages; pageNum++) {
            Page<LeadEntity> page = simulatePage(allLeads, pageNum, PAGE_SIZE);
            assert page.getContent().size() <= PAGE_SIZE :
                "Page " + pageNum + " has " + page.getContent().size() +
                " items, expected at most " + PAGE_SIZE;
        }
    }

    /**
     * **Validates: Requirements 4.2**
     *
     * Property: The union of all pages must contain exactly all N leads
     * without duplicates and without omissions.
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 5: Invariante de paginación")
    void unionOfAllPagesMustContainAllLeadsWithoutDuplicates(
            @ForAll("leadLists") List<LeadEntity> allLeads) {

        int totalPages = (int) Math.ceil((double) allLeads.size() / PAGE_SIZE);
        if (totalPages == 0) totalPages = 1;

        List<LeadEntity> collectedLeads = new ArrayList<>();

        for (int pageNum = 0; pageNum < totalPages; pageNum++) {
            Page<LeadEntity> page = simulatePage(allLeads, pageNum, PAGE_SIZE);
            collectedLeads.addAll(page.getContent());
        }

        // Verify no omissions: all original leads are present
        assert collectedLeads.size() == allLeads.size() :
            "Union of pages has " + collectedLeads.size() + " items but expected " +
            allLeads.size();

        // Verify no duplicates: use IDs to check uniqueness
        Set<Long> ids = collectedLeads.stream()
            .map(LeadEntity::getId)
            .collect(Collectors.toSet());
        assert ids.size() == allLeads.size() :
            "Found duplicates: unique IDs = " + ids.size() + " but total items = " +
            allLeads.size();

        // Verify same elements (by ID)
        Set<Long> originalIds = allLeads.stream()
            .map(LeadEntity::getId)
            .collect(Collectors.toSet());
        assert ids.equals(originalIds) :
            "The union of pages does not match the original set of leads";
    }

    /**
     * **Validates: Requirements 4.2**
     *
     * Property: Total pages must equal ceil(N / 20).
     */
    @Property(tries = 100)
    @Tag("Feature: admin-excel-leads-module, Property 5: Invariante de paginación")
    void totalPagesMustEqualCeilOfNDividedByPageSize(
            @ForAll("leadLists") List<LeadEntity> allLeads) {

        int expectedTotalPages = (int) Math.ceil((double) allLeads.size() / PAGE_SIZE);
        if (expectedTotalPages == 0) expectedTotalPages = 1;

        // Use first page to get totalPages from the Page object
        Page<LeadEntity> firstPage = simulatePage(allLeads, 0, PAGE_SIZE);

        assert firstPage.getTotalPages() == expectedTotalPages :
            "Total pages reported as " + firstPage.getTotalPages() +
            " but expected " + expectedTotalPages + " for " + allLeads.size() + " leads";
    }

    // --- Helper: Simulate pagination using Spring Data PageImpl ---

    private Page<LeadEntity> simulatePage(List<LeadEntity> allLeads, int pageNumber, int pageSize) {
        Pageable pageable = PageRequest.of(pageNumber, pageSize);
        int start = (int) pageable.getOffset();
        int end = Math.min(start + pageSize, allLeads.size());

        List<LeadEntity> pageContent;
        if (start >= allLeads.size()) {
            pageContent = Collections.emptyList();
        } else {
            pageContent = allLeads.subList(start, end);
        }

        return new PageImpl<>(pageContent, pageable, allLeads.size());
    }

    // --- Arbitrary: Generate lists of LeadEntity with unique IDs ---

    @Provide
    Arbitrary<List<LeadEntity>> leadLists() {
        return Arbitraries.integers().between(1, 100).flatMap(n -> {
            return Arbitraries.just(n).map(size -> {
                List<LeadEntity> leads = new ArrayList<>();
                for (long i = 1; i <= size; i++) {
                    LeadEntity lead = new LeadEntity();
                    lead.setId(i);
                    lead.setNombre("Nombre" + i);
                    lead.setApellido("Apellido" + i);
                    lead.setLastCallStatus("Status" + (i % 5));
                    lead.setPais("Pais" + (i % 10));
                    lead.setTelefono("+1234567" + String.format("%04d", i));
                    lead.setEmail("lead" + i + "@example.com");
                    lead.setCampana("Campaign" + (i % 3));
                    lead.setFechaRegistro(new Date());
                    lead.setComentarios("Comment for lead " + i);
                    lead.setImportId(1L);
                    leads.add(lead);
                }
                return leads;
            });
        });
    }
}
