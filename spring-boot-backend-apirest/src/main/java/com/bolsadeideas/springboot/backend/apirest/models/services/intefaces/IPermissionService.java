package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.dto.ActionPermissionDto;
import com.bolsadeideas.springboot.backend.apirest.models.dto.UserPermissionsDto;

import java.util.List;

/**
 * Interfaz del servicio de permisos granulares por módulo.
 * Define operaciones para gestionar permisos de acción y visibilidad de campañas
 * a nivel de rol dentro del módulo LEADS.
 */
public interface IPermissionService {

    // Action permissions

    /**
     * Obtiene los permisos de acción para un rol en un módulo específico.
     * @param roleId ID del rol
     * @param moduleCode código del módulo (e.g., "LEADS")
     * @return lista de permisos de acción con su estado habilitado/deshabilitado
     */
    List<ActionPermissionDto> getActionPermissions(Long roleId, String moduleCode);

    /**
     * Actualiza el estado de un permiso de acción específico.
     * @param roleId ID del rol
     * @param moduleCode código del módulo
     * @param actionCode código de la acción (e.g., "ASSIGN_ADVISOR")
     * @param enabled true para habilitar, false para deshabilitar
     */
    void updateActionPermission(Long roleId, String moduleCode, String actionCode, boolean enabled);

    /**
     * Inicializa los permisos por defecto cuando se asigna un módulo a un rol.
     * Crea registros para todas las acciones con enabled=true.
     * @param roleId ID del rol
     * @param moduleId ID del módulo
     */
    void initializeDefaultPermissions(Long roleId, Long moduleId);

    /**
     * Elimina todos los permisos de acción y visibilidad de campañas para un rol-módulo.
     * Se invoca cuando se desasigna un módulo de un rol.
     * @param roleId ID del rol
     * @param moduleId ID del módulo
     */
    void deletePermissionsForRoleModule(Long roleId, Long moduleId);

    /**
     * Verifica si un usuario tiene un permiso de acción específico.
     * Resuelve el rol del usuario y consulta el permiso correspondiente.
     * @param userId ID del usuario
     * @param moduleCode código del módulo
     * @param actionCode código de la acción
     * @return true si el permiso está habilitado, false en caso contrario
     */
    boolean hasActionPermission(Long userId, String moduleCode, String actionCode);

    // Campaign visibility

    /**
     * Obtiene los IDs de campañas visibles para un rol.
     * Lista vacía significa acceso sin restricciones.
     * @param roleId ID del rol
     * @return lista de IDs de campañas visibles
     */
    List<Long> getVisibleCampaignIds(Long roleId);

    /**
     * Actualiza la configuración de visibilidad de campañas para un rol.
     * Reemplaza la configuración existente con la nueva lista de campañas.
     * @param roleId ID del rol
     * @param campaignIds lista de IDs de campañas visibles
     */
    void updateCampaignVisibility(Long roleId, List<Long> campaignIds);

    /**
     * Obtiene los IDs de campañas visibles para un usuario.
     * Resuelve el rol del usuario y retorna sus campañas visibles.
     * @param userId ID del usuario
     * @return lista de IDs de campañas visibles para el usuario
     */
    List<Long> getUserVisibleCampaignIds(Long userId);

    // Combined user permissions response

    /**
     * Obtiene todos los permisos del usuario para un módulo en una sola respuesta.
     * Combina permisos de acción y visibilidad de campañas.
     * @param userId ID del usuario
     * @param moduleCode código del módulo
     * @return DTO con permisos de acción y campañas visibles
     */
    UserPermissionsDto getUserPermissions(Long userId, String moduleCode);
}
