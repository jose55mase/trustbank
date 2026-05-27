package com.bolsadeideas.springboot.backend.apirest.auth;

import com.bolsadeideas.springboot.backend.apirest.models.dto.ModuleResponse;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
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
            "/api/clientes/**"
    );

    @Autowired
    private IRolService rolService;

    @Autowired
    private IUserService userService;

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
}
