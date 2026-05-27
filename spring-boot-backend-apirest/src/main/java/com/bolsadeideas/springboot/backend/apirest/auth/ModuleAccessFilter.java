package com.bolsadeideas.springboot.backend.apirest.auth;

import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IPermissionService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IRolService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.util.AntPathMatcher;
import org.springframework.web.filter.OncePerRequestFilter;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.util.*;
import java.util.stream.Collectors;

/**
 * Filtro de seguridad que verifica que el usuario autenticado tenga acceso
 * al módulo correspondiente al endpoint solicitado.
 * 
 * Intercepta requests a endpoints protegidos y valida que el rol del usuario
 * tenga asignado el módulo requerido. Si no lo tiene, retorna HTTP 403.
 * 
 * Adicionalmente, verifica permisos de acción granulares para endpoints
 * específicos dentro de un módulo (e.g., asignar, exportar, eliminar en LEADS).
 */
@Component
public class ModuleAccessFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(ModuleAccessFilter.class);

    private static final AntPathMatcher pathMatcher = new AntPathMatcher();

    /**
     * Maps URL patterns to required module codes.
     * Order matters: more specific patterns should be checked first.
     */
    private static final LinkedHashMap<String, String> MODULE_ENDPOINT_MAP = new LinkedHashMap<>();

    static {
        MODULE_ENDPOINT_MAP.put("/api/leads/**", "LEADS");
        MODULE_ENDPOINT_MAP.put("/api/admin/leads/**", "LEADS");
        MODULE_ENDPOINT_MAP.put("/api/admin/advisors/**", "LEADS");
        MODULE_ENDPOINT_MAP.put("/api/documents/**", "DOCUMENTS");
        MODULE_ENDPOINT_MAP.put("/api/admin/documents/**", "DOCUMENT_APPROVAL");
    }

    /**
     * Maps module codes to their action endpoint mappings.
     * Each entry maps "HTTP_METHOD:path_pattern" to an action code.
     * Used for granular action-level permission checks after module access is verified.
     */
    private static final Map<String, Map<String, String>> ACTION_ENDPOINT_MAP = new LinkedHashMap<>();

    static {
        Map<String, String> leadsActions = new LinkedHashMap<>();
        leadsActions.put("POST:/api/admin/leads/assign", "ASSIGN_ADVISOR");
        leadsActions.put("POST:/api/admin/leads/unassign", "UNASSIGN_ADVISOR");
        leadsActions.put("POST:/api/leads/upload", "IMPORT_EXCEL");
        leadsActions.put("POST:/api/leads/import/confirm", "IMPORT_EXCEL");
        leadsActions.put("GET:/api/leads/export", "EXPORT_EXCEL");
        leadsActions.put("PUT:/api/leads/*", "EDIT_LEADS");
        leadsActions.put("DELETE:/api/leads/*", "DELETE_LEADS");
        ACTION_ENDPOINT_MAP.put("LEADS", leadsActions);
    }

    /**
     * Paths that should be skipped by this filter.
     * These are either handled by @Secured or are public/auth endpoints.
     */
    private static final List<String> SKIP_PATHS = Arrays.asList(
            "/api/users/me/modules",
            "/api/roles/**",
            "/api/modules",
            "/api/modules/**",
            "/oauth/**",
            "/api/auth/**",
            "/api/health",
            "/api/public/**",
            "/api/user/**",
            "/api/users/**",
            "/api/supervisor/**",
            "/api/clientes/**"
    );

    @Autowired
    private IRolService rolService;

    @Autowired
    private IUserService userService;

    @Autowired
    private IPermissionService permissionService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();

        // Skip paths that are excluded from module access checking
        for (String skipPath : SKIP_PATHS) {
            if (pathMatcher.match(skipPath, path)) {
                return true;
            }
        }

        // Skip if the path doesn't match any module-protected endpoint
        String requiredModule = getRequiredModule(path);
        if (requiredModule == null) {
            return true;
        }

        return false;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();

        // Skip if not authenticated
        if (authentication == null || !authentication.isAuthenticated()
                || "anonymousUser".equals(authentication.getPrincipal())) {
            filterChain.doFilter(request, response);
            return;
        }

        String path = request.getRequestURI();
        String requiredModule = getRequiredModule(path);

        // If no module is required for this path, continue
        if (requiredModule == null) {
            filterChain.doFilter(request, response);
            return;
        }

        // Skip all module/action checks for ROLE_ADMIN users
        boolean isAdmin = authentication.getAuthorities().stream()
                .anyMatch(a -> "ROLE_ADMIN".equals(a.getAuthority()));
        if (isAdmin) {
            filterChain.doFilter(request, response);
            return;
        }

        // Extract user email from authentication
        String email = authentication.getName();
        UserEntity user = userService.findByemail(email);

        if (user == null) {
            filterChain.doFilter(request, response);
            return;
        }

        // Load user's modules
        List<ModuleResponse> userModules = rolService.getUserModules(user.getId());
        Set<String> userModuleCodes = userModules.stream()
                .map(ModuleResponse::getCode)
                .collect(Collectors.toSet());

        // Check if user has the required module
        if (!userModuleCodes.contains(requiredModule)) {
            log.warn("Unauthorized access attempt: userId={}, endpoint={}, requiredModule={}",
                    user.getId(), path, requiredModule);

            response.setStatus(HttpServletResponse.SC_FORBIDDEN);
            response.setContentType("application/json;charset=UTF-8");

            Map<String, String> errorBody = new HashMap<>();
            errorBody.put("error", "MODULE_ACCESS_DENIED");
            errorBody.put("message", "No tienes acceso a este módulo");

            response.getWriter().write(objectMapper.writeValueAsString(errorBody));
            return;
        }

        // Action-level permission check
        String actionCode = resolveActionCode(request.getMethod(), path, requiredModule);
        if (actionCode != null) {
            boolean hasPermission = permissionService.hasActionPermission(user.getId(), requiredModule, actionCode);
            if (!hasPermission) {
                log.warn("Action permission denied: userId={}, endpoint={}, module={}, action={}",
                        user.getId(), path, requiredModule, actionCode);

                response.setStatus(HttpServletResponse.SC_FORBIDDEN);
                response.setContentType("application/json;charset=UTF-8");

                Map<String, String> errorBody = new LinkedHashMap<>();
                errorBody.put("error", "ACTION_PERMISSION_DENIED");
                errorBody.put("message", "No tienes permiso para realizar esta acción");
                errorBody.put("action", actionCode);

                response.getWriter().write(objectMapper.writeValueAsString(errorBody));
                return;
            }
        }

        filterChain.doFilter(request, response);
    }

    /**
     * Determines the required module code for a given request path.
     *
     * @param path the request URI
     * @return the module code required, or null if no module is required
     */
    private String getRequiredModule(String path) {
        for (Map.Entry<String, String> entry : MODULE_ENDPOINT_MAP.entrySet()) {
            if (pathMatcher.match(entry.getKey(), path)) {
                return entry.getValue();
            }
        }
        return null;
    }

    /**
     * Resolves the action code for a given HTTP method, path, and module.
     * Uses the ACTION_ENDPOINT_MAP to match the request against known action endpoints.
     * Supports exact path matching and Ant-style wildcard patterns.
     *
     * @param method the HTTP method (GET, POST, PUT, DELETE)
     * @param path the request URI
     * @param moduleCode the module code to look up actions for
     * @return the action code if matched, or null if no action mapping applies
     */
    private String resolveActionCode(String method, String path, String moduleCode) {
        Map<String, String> moduleActions = ACTION_ENDPOINT_MAP.get(moduleCode);
        if (moduleActions == null) {
            return null;
        }

        for (Map.Entry<String, String> entry : moduleActions.entrySet()) {
            String key = entry.getKey();
            int colonIndex = key.indexOf(':');
            if (colonIndex < 0) {
                continue;
            }

            String mappedMethod = key.substring(0, colonIndex);
            String mappedPath = key.substring(colonIndex + 1);

            if (mappedMethod.equalsIgnoreCase(method) && pathMatcher.match(mappedPath, path)) {
                return entry.getValue();
            }
        }

        return null;
    }
}
