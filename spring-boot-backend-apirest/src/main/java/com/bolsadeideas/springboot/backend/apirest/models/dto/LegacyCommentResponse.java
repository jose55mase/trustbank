package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * DTO que representa el comentario legado (campo comentarios de la tabla leads).
 * Se marca con isLegacy: true y no tiene autor asociado.
 */
public class LegacyCommentResponse {

    private String text;
    private boolean isLegacy;

    public LegacyCommentResponse() {
    }

    public LegacyCommentResponse(String text) {
        this.text = text;
        this.isLegacy = true;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }

    public boolean getIsLegacy() {
        return isLegacy;
    }

    public void setIsLegacy(boolean isLegacy) {
        this.isLegacy = isLegacy;
    }
}
