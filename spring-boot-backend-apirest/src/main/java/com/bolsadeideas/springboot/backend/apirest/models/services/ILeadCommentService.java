package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.List;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;

/**
 * Interfaz del servicio de gestión de comentarios de Leads.
 * Define las operaciones de consulta, creación, edición y eliminación de comentarios con autoría.
 */
public interface ILeadCommentService {

    /**
     * Retorna todos los comentarios asociados a un lead, ordenados por fecha de creación ascendente.
     */
    List<LeadCommentEntity> findByLeadId(Long leadId);

    /**
     * Crea un nuevo comentario para un lead con el usuario indicado como autor.
     * Valida que el lead exista antes de persistir.
     */
    LeadCommentEntity create(Long leadId, Long userId, String text);

    /**
     * Actualiza el texto de un comentario existente.
     * Valida que el usuario sea el autor del comentario (ownership).
     */
    LeadCommentEntity update(Long commentId, Long userId, String text);

    /**
     * Elimina un comentario existente de forma permanente.
     * Valida que el usuario sea el autor del comentario (ownership).
     */
    void delete(Long commentId, Long userId);
}
