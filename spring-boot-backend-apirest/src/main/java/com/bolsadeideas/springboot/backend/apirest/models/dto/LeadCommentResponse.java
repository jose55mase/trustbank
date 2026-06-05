package com.bolsadeideas.springboot.backend.apirest.models.dto;

import java.util.Date;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadCommentEntity;

/**
 * DTO que representa un comentario autoral en la respuesta del endpoint GET.
 * Incluye el nombre del autor compuesto desde firstName + lastName del usuario.
 */
public class LeadCommentResponse {

    private Long id;
    private Long leadId;
    private Long userId;
    private String authorName;
    private String text;
    private Date createdAt;
    private Date editedAt;
    private boolean isLegacy;

    public LeadCommentResponse() {
    }

    /**
     * Construye el DTO a partir de la entidad LeadCommentEntity.
     * El authorName se obtiene del método getFullName() del UserEntity asociado.
     */
    public static LeadCommentResponse fromEntity(LeadCommentEntity entity) {
        LeadCommentResponse dto = new LeadCommentResponse();
        dto.setId(entity.getId());
        dto.setLeadId(entity.getLeadId());
        dto.setUserId(entity.getUser().getId());
        dto.setAuthorName(entity.getUser().getFullName());
        dto.setText(entity.getText());
        dto.setCreatedAt(entity.getCreatedAt());
        dto.setEditedAt(entity.getEditedAt());
        dto.setIsLegacy(false);
        return dto;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getLeadId() {
        return leadId;
    }

    public void setLeadId(Long leadId) {
        this.leadId = leadId;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getAuthorName() {
        return authorName;
    }

    public void setAuthorName(String authorName) {
        this.authorName = authorName;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public Date getEditedAt() {
        return editedAt;
    }

    public void setEditedAt(Date editedAt) {
        this.editedAt = editedAt;
    }

    public boolean getIsLegacy() {
        return isLegacy;
    }

    public void setIsLegacy(boolean isLegacy) {
        this.isLegacy = isLegacy;
    }
}
