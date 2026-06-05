package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.List;
import java.util.stream.Collectors;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;

/**
 * DTO de respuesta para el endpoint GET /api/leads/{leadId}/comments.
 * Estructura: { legacyComment: {...} | null, comments: [...] }
 * 
 * - legacyComment: el comentario del campo comentarios de leads (null si está vacío)
 * - comments: lista de comentarios autorales ordenados por createdAt ASC
 */
public class LeadCommentsListResponse {

    private LegacyCommentResponse legacyComment;
    private List<LeadCommentResponse> comments;

    public LeadCommentsListResponse() {
    }

    public LeadCommentsListResponse(LegacyCommentResponse legacyComment, List<LeadCommentResponse> comments) {
        this.legacyComment = legacyComment;
        this.comments = comments;
    }

    /**
     * Factory method para construir la respuesta completa.
     * 
     * @param legacyText el texto del campo comentarios de la tabla leads (puede ser null)
     * @param entities la lista de entidades LeadCommentEntity ordenadas por createdAt ASC
     * @return el DTO de respuesta estructurado
     */
    public static LeadCommentsListResponse build(String legacyText, List<LeadCommentEntity> entities) {
        // Legacy comment: solo si no es null ni vacío/blank
        LegacyCommentResponse legacy = null;
        if (legacyText != null && !legacyText.trim().isEmpty()) {
            legacy = new LegacyCommentResponse(legacyText);
        }

        // Mapear entidades a DTOs
        List<LeadCommentResponse> comments = entities.stream()
                .map(LeadCommentResponse::fromEntity)
                .collect(Collectors.toList());

        return new LeadCommentsListResponse(legacy, comments);
    }

    public LegacyCommentResponse getLegacyComment() {
        return legacyComment;
    }

    public void setLegacyComment(LegacyCommentResponse legacyComment) {
        this.legacyComment = legacyComment;
    }

    public List<LeadCommentResponse> getComments() {
        return comments;
    }

    public void setComments(List<LeadCommentResponse> comments) {
        this.comments = comments;
    }
}
