package com.bolsadeideas.springboot.backend.apirest.models.entity;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;

import java.util.Date;

/**
 * Feature: admin-excel-leads-module, Property 4: Persistencia round-trip de datos del Lead
 *
 * Para cualquier Lead con datos válidos, al establecer valores en la entidad y luego recuperarlos,
 * todos los campos (nombre, apellido, lastCallStatus, país, teléfono, email, campaña,
 * fechaRegistro, comentarios, importId) deben ser idénticos a los valores originales.
 *
 * Este test verifica la consistencia round-trip de los datos a través de los accessors de la entidad,
 * garantizando que no hay pérdida ni transformación de datos en el modelo.
 *
 * **Validates: Requirements 3.2, 3.5, 7.3**
 */
class LeadEntityRoundTripPropertyTest {

    /**
     * **Validates: Requirements 3.2, 3.5, 7.3**
     *
     * Property: For any valid LeadEntity data, setting all fields and then reading them back
     * must return identical values. This ensures data integrity through the entity's accessors.
     */
    @Property(tries = 150)
    void allFieldsMustSurviveRoundTripThroughEntity(
            @ForAll("validLeadData") LeadTestData data) {

        // Create a new entity and set all fields
        LeadEntity entity = new LeadEntity();
        entity.setNombre(data.nombre);
        entity.setApellido(data.apellido);
        entity.setLastCallStatus(data.lastCallStatus);
        entity.setPais(data.pais);
        entity.setTelefono(data.telefono);
        entity.setEmail(data.email);
        entity.setCampana(data.campana);
        entity.setFechaRegistro(data.fechaRegistro);
        entity.setComentarios(data.comentarios);
        entity.setImportId(data.importId);

        // Verify all getters return the exact same values
        assert entity.getNombre() != null && entity.getNombre().equals(data.nombre) :
            "nombre mismatch: set '" + data.nombre + "' but got '" + entity.getNombre() + "'";
        assert entity.getApellido() != null && entity.getApellido().equals(data.apellido) :
            "apellido mismatch: set '" + data.apellido + "' but got '" + entity.getApellido() + "'";
        assert entity.getLastCallStatus() != null && entity.getLastCallStatus().equals(data.lastCallStatus) :
            "lastCallStatus mismatch: set '" + data.lastCallStatus + "' but got '" + entity.getLastCallStatus() + "'";
        assert entity.getPais() != null && entity.getPais().equals(data.pais) :
            "pais mismatch: set '" + data.pais + "' but got '" + entity.getPais() + "'";
        assert entity.getTelefono() != null && entity.getTelefono().equals(data.telefono) :
            "telefono mismatch: set '" + data.telefono + "' but got '" + entity.getTelefono() + "'";
        assert entity.getEmail() != null && entity.getEmail().equals(data.email) :
            "email mismatch: set '" + data.email + "' but got '" + entity.getEmail() + "'";
        assert entity.getCampana() != null && entity.getCampana().equals(data.campana) :
            "campana mismatch: set '" + data.campana + "' but got '" + entity.getCampana() + "'";
        assert entity.getFechaRegistro() != null && entity.getFechaRegistro().equals(data.fechaRegistro) :
            "fechaRegistro mismatch: set '" + data.fechaRegistro + "' but got '" + entity.getFechaRegistro() + "'";
        assert entity.getComentarios() != null && entity.getComentarios().equals(data.comentarios) :
            "comentarios mismatch: set '" + data.comentarios + "' but got '" + entity.getComentarios() + "'";
        assert entity.getImportId() != null && entity.getImportId().equals(data.importId) :
            "importId mismatch: set '" + data.importId + "' but got '" + entity.getImportId() + "'";
    }

    /**
     * **Validates: Requirements 3.2, 3.5, 7.3**
     *
     * Property: Setting a field value and then overwriting it with a new value must
     * always reflect the latest value. This ensures no stale data remains.
     */
    @Property(tries = 100)
    void overwritingFieldsMustReflectLatestValue(
            @ForAll("validLeadData") LeadTestData firstData,
            @ForAll("validLeadData") LeadTestData secondData) {

        LeadEntity entity = new LeadEntity();

        // Set first values
        entity.setNombre(firstData.nombre);
        entity.setApellido(firstData.apellido);
        entity.setLastCallStatus(firstData.lastCallStatus);
        entity.setPais(firstData.pais);
        entity.setTelefono(firstData.telefono);
        entity.setEmail(firstData.email);
        entity.setCampana(firstData.campana);
        entity.setFechaRegistro(firstData.fechaRegistro);
        entity.setComentarios(firstData.comentarios);
        entity.setImportId(firstData.importId);

        // Overwrite with second values
        entity.setNombre(secondData.nombre);
        entity.setApellido(secondData.apellido);
        entity.setLastCallStatus(secondData.lastCallStatus);
        entity.setPais(secondData.pais);
        entity.setTelefono(secondData.telefono);
        entity.setEmail(secondData.email);
        entity.setCampana(secondData.campana);
        entity.setFechaRegistro(secondData.fechaRegistro);
        entity.setComentarios(secondData.comentarios);
        entity.setImportId(secondData.importId);

        // All getters must return the second (latest) values
        assert entity.getNombre().equals(secondData.nombre) :
            "nombre should be '" + secondData.nombre + "' after overwrite";
        assert entity.getApellido().equals(secondData.apellido) :
            "apellido should be '" + secondData.apellido + "' after overwrite";
        assert entity.getLastCallStatus().equals(secondData.lastCallStatus) :
            "lastCallStatus should be '" + secondData.lastCallStatus + "' after overwrite";
        assert entity.getPais().equals(secondData.pais) :
            "pais should be '" + secondData.pais + "' after overwrite";
        assert entity.getTelefono().equals(secondData.telefono) :
            "telefono should be '" + secondData.telefono + "' after overwrite";
        assert entity.getEmail().equals(secondData.email) :
            "email should be '" + secondData.email + "' after overwrite";
        assert entity.getCampana().equals(secondData.campana) :
            "campana should be '" + secondData.campana + "' after overwrite";
        assert entity.getFechaRegistro().equals(secondData.fechaRegistro) :
            "fechaRegistro should be '" + secondData.fechaRegistro + "' after overwrite";
        assert entity.getComentarios().equals(secondData.comentarios) :
            "comentarios should be '" + secondData.comentarios + "' after overwrite";
        assert entity.getImportId().equals(secondData.importId) :
            "importId should be '" + secondData.importId + "' after overwrite";
    }

    /**
     * **Validates: Requirements 3.2, 3.5, 7.3**
     *
     * Property: Two LeadEntity instances with the same data must have identical field values.
     * This ensures consistency when creating multiple entities from the same source data.
     */
    @Property(tries = 100)
    void twoEntitiesWithSameDataMustHaveIdenticalFields(
            @ForAll("validLeadData") LeadTestData data) {

        LeadEntity entity1 = createEntityFromData(data);
        LeadEntity entity2 = createEntityFromData(data);

        // Both entities must have identical field values
        assert entity1.getNombre().equals(entity2.getNombre()) :
            "nombre differs between two entities with same data";
        assert entity1.getApellido().equals(entity2.getApellido()) :
            "apellido differs between two entities with same data";
        assert entity1.getLastCallStatus().equals(entity2.getLastCallStatus()) :
            "lastCallStatus differs between two entities with same data";
        assert entity1.getPais().equals(entity2.getPais()) :
            "pais differs between two entities with same data";
        assert entity1.getTelefono().equals(entity2.getTelefono()) :
            "telefono differs between two entities with same data";
        assert entity1.getEmail().equals(entity2.getEmail()) :
            "email differs between two entities with same data";
        assert entity1.getCampana().equals(entity2.getCampana()) :
            "campana differs between two entities with same data";
        assert entity1.getFechaRegistro().equals(entity2.getFechaRegistro()) :
            "fechaRegistro differs between two entities with same data";
        assert entity1.getComentarios().equals(entity2.getComentarios()) :
            "comentarios differs between two entities with same data";
        assert entity1.getImportId().equals(entity2.getImportId()) :
            "importId differs between two entities with same data";
    }

    // --- Helper Methods ---

    private LeadEntity createEntityFromData(LeadTestData data) {
        LeadEntity entity = new LeadEntity();
        entity.setNombre(data.nombre);
        entity.setApellido(data.apellido);
        entity.setLastCallStatus(data.lastCallStatus);
        entity.setPais(data.pais);
        entity.setTelefono(data.telefono);
        entity.setEmail(data.email);
        entity.setCampana(data.campana);
        entity.setFechaRegistro(data.fechaRegistro);
        entity.setComentarios(data.comentarios);
        entity.setImportId(data.importId);
        return entity;
    }

    // --- Arbitraries / Providers ---

    @Provide
    Arbitrary<LeadTestData> validLeadData() {
        Arbitrary<String> nombres = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(50);
        Arbitrary<String> apellidos = Arbitraries.strings()
            .alpha().ofMinLength(1).ofMaxLength(50);
        Arbitrary<String> statuses = Arbitraries.of(
            "Contactado", "No contesta", "Interesado", "Rechazado",
            "Pendiente", "En seguimiento", "Cerrado");
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
            "Lanzamiento Producto", "Reactivación", "Referidos");
        Arbitrary<Date> fechas = Arbitraries.longs()
            .between(946684800000L, 1735689600000L) // 2000-01-01 to 2025-01-01
            .map(Date::new);
        Arbitrary<String> comentarios = Arbitraries.strings()
            .alpha().ofMinLength(0).ofMaxLength(200)
            .map(s -> s.isEmpty() ? "Sin comentarios" : s);
        Arbitrary<Long> importIds = Arbitraries.longs().between(1L, 10000L);

        // jqwik Combinators.combine supports max 8 params, so we split into two groups
        Arbitrary<String[]> firstGroup = Combinators.combine(
            nombres, apellidos, statuses, paises, telefonos
        ).as((n, a, s, p, t) -> new String[]{n, a, s, p, t});

        Arbitrary<Object[]> secondGroup = Combinators.combine(
            emails, campanas, fechas, comentarios, importIds
        ).as((e, c, f, com, imp) -> new Object[]{e, c, f, com, imp});

        return Combinators.combine(firstGroup, secondGroup)
            .as((first, second) -> new LeadTestData(
                first[0], first[1], first[2], first[3], first[4],
                (String) second[0], (String) second[1], (Date) second[2],
                (String) second[3], (Long) second[4]
            ));
    }

    // --- Test Data Class ---

    static class LeadTestData {
        final String nombre;
        final String apellido;
        final String lastCallStatus;
        final String pais;
        final String telefono;
        final String email;
        final String campana;
        final Date fechaRegistro;
        final String comentarios;
        final Long importId;

        LeadTestData(String nombre, String apellido, String lastCallStatus,
                     String pais, String telefono, String email, String campana,
                     Date fechaRegistro, String comentarios, Long importId) {
            this.nombre = nombre;
            this.apellido = apellido;
            this.lastCallStatus = lastCallStatus;
            this.pais = pais;
            this.telefono = telefono;
            this.email = email;
            this.campana = campana;
            this.fechaRegistro = fechaRegistro;
            this.comentarios = comentarios;
            this.importId = importId;
        }

        @Override
        public String toString() {
            return "LeadTestData{nombre='" + nombre + "', apellido='" + apellido +
                   "', email='" + email + "', importId=" + importId + "}";
        }
    }
}
