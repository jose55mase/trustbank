package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.ArrayList;
import java.util.List;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

/**
 * Resultado del parsing de filas del archivo Excel.
 * Contiene la lista de LeadEntity válidos y la lista de errores encontrados.
 */
public class ParseResult {

    private List<LeadEntity> validLeads;
    private List<String> errors;

    public ParseResult() {
        this.validLeads = new ArrayList<>();
        this.errors = new ArrayList<>();
    }

    public ParseResult(List<LeadEntity> validLeads, List<String> errors) {
        this.validLeads = validLeads;
        this.errors = errors;
    }

    public List<LeadEntity> getValidLeads() {
        return validLeads;
    }

    public void setValidLeads(List<LeadEntity> validLeads) {
        this.validLeads = validLeads;
    }

    public List<String> getErrors() {
        return errors;
    }

    public void setErrors(List<String> errors) {
        this.errors = errors;
    }

    public void addValidLead(LeadEntity lead) {
        this.validLeads.add(lead);
    }

    public void addError(String error) {
        this.errors.add(error);
    }

    public int getSuccessCount() {
        return validLeads.size();
    }

    public int getErrorCount() {
        return errors.size();
    }
}
