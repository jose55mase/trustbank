package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Component;

import com.bolsadeideas.springboot.backend.apirest.models.dao.ILeadDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;

/**
 * Motor de deduplicación que detecta leads duplicados durante la importación.
 * Cuando un duplicado es detectado, actualiza los datos del lead existente.
 *
 * Criterio de duplicado: un lead es duplicado si coincide en nombre+apellido+email
 * (los tres campos que NO deben cambiar). Los demás campos (teléfono, país, etc.) se actualizan.
 */
@Component
public class DeduplicationEngine {

    @Autowired
    private ILeadDao leadDao;

    public String normalizeEmail(String email) {
        if (email == null) return null;
        String normalized = email.trim().toLowerCase();
        return normalized.isEmpty() ? null : normalized;
    }

    public String normalizePhone(String phone) {
        if (phone == null) return null;
        String normalized = phone.replaceAll("[\\s\\-\\(\\)]", "");
        return normalized.isEmpty() ? null : normalized;
    }

    /**
     * Genera una clave única para un lead basada en nombre+apellido+email (los campos inmutables).
     */
    private String buildKey(String nombre, String apellido, String email) {
        String n = (nombre != null) ? nombre.trim().toLowerCase() : "";
        String a = (apellido != null) ? apellido.trim().toLowerCase() : "";
        String e = (email != null) ? email.trim().toLowerCase() : "";
        return n + "|" + a + "|" + e;
    }

    /**
     * Filtra duplicados y actualiza leads existentes con los datos nuevos.
     * Un candidato es duplicado si coincide en nombre+apellido+email con un lead existente.
     * Los demás campos se actualizan en el lead existente.
     */
    public DeduplicationResult filterDuplicates(List<LeadEntity> candidates) {
        // Cargar TODOS los leads existentes y construir un mapa por clave
        List<LeadEntity> allExistingLeads = leadDao.findAll();
        java.util.Map<String, LeadEntity> existingByKey = new java.util.HashMap<>();
        for (LeadEntity existing : allExistingLeads) {
            String key = buildKey(existing.getNombre(), existing.getApellido(), existing.getEmail());
            existingByKey.put(key, existing);
        }

        // Set para deduplicación intra-archivo
        Set<String> seenKeys = new HashSet<>();

        List<LeadEntity> uniqueLeads = new ArrayList<>();
        List<LeadEntity> updatedLeads = new ArrayList<>();
        int duplicateCount = 0;

        for (LeadEntity candidate : candidates) {
            String key = buildKey(candidate.getNombre(), candidate.getApellido(), candidate.getEmail());

            // Si la clave está vacía (sin nombre, apellido ni email), importar sin verificación
            if (key.equals("||")) {
                uniqueLeads.add(candidate);
                continue;
            }

            // Verificar duplicado intra-archivo
            if (seenKeys.contains(key)) {
                duplicateCount++;
                continue;
            }

            // Verificar contra base de datos
            LeadEntity existingLead = existingByKey.get(key);

            if (existingLead != null) {
                // Duplicado encontrado: actualizar campos que pueden cambiar
                updateLeadFields(existingLead, candidate);
                updatedLeads.add(existingLead);
                duplicateCount++;
            } else {
                // Nuevo lead
                uniqueLeads.add(candidate);
            }

            seenKeys.add(key);
        }

        return new DeduplicationResult(uniqueLeads, updatedLeads, duplicateCount);
    }

    /**
     * Actualiza los campos del lead existente con los valores del candidato.
     * Solo actualiza campos que PUEDEN cambiar (no nombre, apellido ni email).
     */
    private void updateLeadFields(LeadEntity existing, LeadEntity candidate) {
        // Teléfono: siempre actualizar si tiene valor
        if (candidate.getTelefono() != null && !candidate.getTelefono().trim().isEmpty()) {
            existing.setTelefono(candidate.getTelefono());
        }
        // País
        if (candidate.getPais() != null && !candidate.getPais().trim().isEmpty()) {
            existing.setPais(candidate.getPais());
        }
        // Last Call Status
        if (candidate.getLastCallStatus() != null && !candidate.getLastCallStatus().trim().isEmpty()) {
            existing.setLastCallStatus(candidate.getLastCallStatus());
        }
        // Campaña
        if (candidate.getCampana() != null && !candidate.getCampana().trim().isEmpty()) {
            existing.setCampana(candidate.getCampana());
        }
        // Comentarios
        if (candidate.getComentarios() != null && !candidate.getComentarios().trim().isEmpty()) {
            existing.setComentarios(candidate.getComentarios());
        }
    }
}
