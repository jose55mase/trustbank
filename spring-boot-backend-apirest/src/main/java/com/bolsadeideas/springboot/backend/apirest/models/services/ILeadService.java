package com.bolsadeideas.springboot.backend.apirest.models.services;

import java.io.IOException;
import java.util.Map;

import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.web.multipart.MultipartFile;

import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.LeadImportEntity;

/**
 * Interfaz del servicio de gestión de Leads.
 * Define las operaciones de importación desde Excel, consulta, búsqueda y actualización.
 */
public interface ILeadService {

    /**
     * Procesa la carga de un archivo Excel: parsea encabezados, ejecuta el motor de mapeo
     * y retorna una vista previa con los headers, el mapeo detectado y las primeras 5 filas.
     */
    MappingPreviewResponse processExcelUpload(MultipartFile file) throws IOException;

    /**
     * Confirma la importación: crea un registro de importación, parsea las filas con el mapeo
     * proporcionado, guarda los leads válidos y actualiza los contadores de la importación.
     */
    ImportResultResponse confirmImport(MultipartFile file, Map<Integer, String> columnMapping, Long adminId) throws IOException;

    /**
     * Retorna todos los leads con paginación.
     */
    Page<LeadEntity> findAll(Pageable pageable);

    /**
     * Busca leads por término en múltiples campos con paginación.
     */
    Page<LeadEntity> searchByTerm(String term, Pageable pageable);

    /**
     * Busca un lead por su ID. Lanza excepción si no existe.
     */
    LeadEntity findById(Long id);

    /**
     * Actualiza un lead existente. Valida formato de email y teléfono antes de guardar.
     */
    LeadEntity update(Long id, LeadEntity lead);

    /**
     * Elimina un lead por su ID. Lanza excepción si no existe.
     */
    void delete(Long id);

    /**
     * Retorna el historial de importaciones con paginación.
     */
    Page<LeadImportEntity> getImportHistory(Pageable pageable);
}
