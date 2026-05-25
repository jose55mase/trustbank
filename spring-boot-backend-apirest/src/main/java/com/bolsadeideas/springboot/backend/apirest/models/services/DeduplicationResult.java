package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.ArrayList;
import java.util.List;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

/**
 * DTO que encapsula el resultado del proceso de deduplicación.
 * Contiene las listas de leads únicos (nuevos), leads actualizados (duplicados con datos nuevos)
 * y el conteo de duplicados detectados.
 */
public class DeduplicationResult {

    private List<LeadEntity> uniqueLeads;
    private List<LeadEntity> updatedLeads;
    private int duplicateCount;

    public DeduplicationResult() {
        this.uniqueLeads = new ArrayList<>();
        this.updatedLeads = new ArrayList<>();
    }

    public DeduplicationResult(List<LeadEntity> uniqueLeads, List<LeadEntity> updatedLeads, int duplicateCount) {
        this.uniqueLeads = uniqueLeads;
        this.updatedLeads = updatedLeads;
        this.duplicateCount = duplicateCount;
    }

    public List<LeadEntity> getUniqueLeads() {
        return uniqueLeads;
    }

    public void setUniqueLeads(List<LeadEntity> uniqueLeads) {
        this.uniqueLeads = uniqueLeads;
    }

    public List<LeadEntity> getUpdatedLeads() {
        return updatedLeads;
    }

    public void setUpdatedLeads(List<LeadEntity> updatedLeads) {
        this.updatedLeads = updatedLeads;
    }

    public int getDuplicateCount() {
        return duplicateCount;
    }

    public void setDuplicateCount(int duplicateCount) {
        this.duplicateCount = duplicateCount;
    }
}
