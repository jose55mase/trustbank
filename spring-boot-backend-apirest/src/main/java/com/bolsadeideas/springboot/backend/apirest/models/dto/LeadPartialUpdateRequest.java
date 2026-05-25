package com.bolsadeideas.springboot.backend.apirest.models.dto;

/**
 * Request DTO para actualización parcial de un lead por parte de un supervisor.
 * Todos los campos son opcionales; solo se actualizan los campos con valor no nulo.
 */
public class LeadPartialUpdateRequest {

    private String nombre;
    private String apellido;
    private String telefono;
    private String email;
    private String pais;
    private String campana;
    private String lastCallStatus;
    private String comentarios;

    public LeadPartialUpdateRequest() {
    }

    public LeadPartialUpdateRequest(String nombre, String apellido, String telefono, String email, String pais, String campana, String lastCallStatus, String comentarios) {
        this.nombre = nombre;
        this.apellido = apellido;
        this.telefono = telefono;
        this.email = email;
        this.pais = pais;
        this.campana = campana;
        this.lastCallStatus = lastCallStatus;
        this.comentarios = comentarios;
    }

    public String getNombre() {
        return nombre;
    }

    public void setNombre(String nombre) {
        this.nombre = nombre;
    }

    public String getApellido() {
        return apellido;
    }

    public void setApellido(String apellido) {
        this.apellido = apellido;
    }

    public String getTelefono() {
        return telefono;
    }

    public void setTelefono(String telefono) {
        this.telefono = telefono;
    }

    public String getEmail() {
        return email;
    }

    public void setEmail(String email) {
        this.email = email;
    }

    public String getPais() {
        return pais;
    }

    public void setPais(String pais) {
        this.pais = pais;
    }

    public String getCampana() {
        return campana;
    }

    public void setCampana(String campana) {
        this.campana = campana;
    }

    public String getLastCallStatus() {
        return lastCallStatus;
    }

    public void setLastCallStatus(String lastCallStatus) {
        this.lastCallStatus = lastCallStatus;
    }

    public String getComentarios() {
        return comentarios;
    }

    public void setComentarios(String comentarios) {
        this.comentarios = comentarios;
    }
}
