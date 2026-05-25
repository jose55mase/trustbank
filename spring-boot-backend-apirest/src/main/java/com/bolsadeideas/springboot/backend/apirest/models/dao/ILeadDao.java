package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.domain.Sort;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

public interface ILeadDao extends JpaRepository<LeadEntity, Long> {

    Page<LeadEntity> findAll(Pageable pageable);

    @Query("SELECT l FROM LeadEntity l WHERE " +
           "LOWER(l.nombre) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.apellido) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.lastCallStatus) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.pais) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.telefono) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.email) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.campana) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.comentarios) LIKE LOWER(CONCAT('%', :term, '%'))")
    Page<LeadEntity> searchByTerm(@Param("term") String term, Pageable pageable);

    List<LeadEntity> findByImportId(Long importId);

    @Query("SELECT LOWER(TRIM(l.email)) FROM LeadEntity l WHERE l.email IS NOT NULL AND TRIM(l.email) <> ''")
    List<String> findAllNormalizedEmails();

    @Query("SELECT l FROM LeadEntity l WHERE LOWER(TRIM(l.email)) = :email")
    List<LeadEntity> findByNormalizedEmail(@Param("email") String email);

    @Query("SELECT l FROM LeadEntity l WHERE l.telefono IS NOT NULL AND TRIM(l.telefono) <> ''")
    List<LeadEntity> findAllWithPhone();

    @Query("SELECT l.telefono FROM LeadEntity l WHERE l.telefono IS NOT NULL AND TRIM(l.telefono) <> ''")
    List<String> findAllPhones();

    @Query("SELECT l FROM LeadEntity l WHERE LOWER(TRIM(l.nombre)) = :nombre AND LOWER(TRIM(l.apellido)) = :apellido")
    List<LeadEntity> findByNormalizedName(@Param("nombre") String nombre, @Param("apellido") String apellido);

    @Query("SELECT CONCAT(LOWER(TRIM(l.nombre)), '|', LOWER(TRIM(l.apellido))) FROM LeadEntity l WHERE l.nombre IS NOT NULL AND TRIM(l.nombre) <> ''")
    List<String> findAllNormalizedFullNames();

    List<LeadEntity> findAll(Sort sort);

    Page<LeadEntity> findByCampana(String campana, Pageable pageable);

    @Query("SELECT l FROM LeadEntity l WHERE l.campana = :campana AND (" +
           "LOWER(l.nombre) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.apellido) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.telefono) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.email) LIKE LOWER(CONCAT('%', :term, '%')))")
    Page<LeadEntity> searchByCampanaAndTerm(@Param("campana") String campana, @Param("term") String term, Pageable pageable);

    // --- Métodos para asignación directa de leads a asesores ---

    Page<LeadEntity> findByAdvisorId(Long advisorId, Pageable pageable);

    Page<LeadEntity> findByAdvisorIsNull(Pageable pageable);

    @Query("SELECT l FROM LeadEntity l WHERE l.advisor.id = :advisorId AND (" +
           "LOWER(l.nombre) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.apellido) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.telefono) LIKE LOWER(CONCAT('%', :term, '%')) OR " +
           "LOWER(l.email) LIKE LOWER(CONCAT('%', :term, '%')))")
    Page<LeadEntity> searchByAdvisorIdAndTerm(
        @Param("advisorId") Long advisorId,
        @Param("term") String term,
        Pageable pageable);

    @Query("SELECT COUNT(l) FROM LeadEntity l WHERE l.advisor.id = :advisorId")
    Long countByAdvisorId(@Param("advisorId") Long advisorId);

    @Modifying(clearAutomatically = true)
    @Query(value = "UPDATE leads SET advisor_id = :advisorId WHERE id IN :leadIds", nativeQuery = true)
    int bulkAssign(@Param("leadIds") List<Long> leadIds, @Param("advisorId") Long advisorId);

    @Modifying(clearAutomatically = true)
    @Query(value = "UPDATE leads SET advisor_id = NULL WHERE id IN :leadIds", nativeQuery = true)
    int bulkUnassign(@Param("leadIds") List<Long> leadIds);
}
