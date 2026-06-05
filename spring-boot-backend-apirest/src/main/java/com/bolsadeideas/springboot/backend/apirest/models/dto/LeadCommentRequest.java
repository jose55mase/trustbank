package com.bolsadeideas.springboot.backend.apirest.models.dto;

import javax.validation.constraints.NotBlank;
import javax.validation.constraints.Size;

/**
 * Request DTO para crear o editar un comentario de lead.
 * Valida que el texto no sea vacío/blanco y no exceda 2000 caracteres.
 */
public class LeadCommentRequest {

    @NotBlank(message = "El texto del comentario no puede estar vacío")
    @Size(max = 2000, message = "El texto del comentario no puede exceder 2000 caracteres")
    private String text;

    public LeadCommentRequest() {
    }

    public LeadCommentRequest(String text) {
        this.text = text;
    }

    public String getText() {
        return text;
    }

    public void setText(String text) {
        this.text = text;
    }
}
