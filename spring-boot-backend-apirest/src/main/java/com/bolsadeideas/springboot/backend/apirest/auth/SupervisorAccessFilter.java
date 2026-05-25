package com.bolsadeideas.springboot.backend.apirest.auth;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
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
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Filtro de seguridad que intercepta requests de usuarios con ROLE_SUPERVISOR
 * para bloquear operaciones no permitidas (POST/DELETE en /api/leads/**).
 *
 * Los supervisores solo pueden:
 * - GET y PUT en /api/supervisor/leads/**
 * - No pueden crear ni eliminar leads
 */
@Component
public class SupervisorAccessFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger(SupervisorAccessFilter.class);

    private static final AntPathMatcher pathMatcher = new AntPathMatcher();

    private static final String LEADS_PATTERN = "/api/leads/**";

    @Autowired
    private IUserService userService;

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    protected boolean shouldNotFilter(HttpServletRequest request) {
        String path = request.getRequestURI();
        String method = request.getMethod();

        // Only apply this filter to POST/DELETE on /api/leads/**
        if (pathMatcher.match(LEADS_PATTERN, path)) {
            if ("POST".equalsIgnoreCase(method) || "DELETE".equalsIgnoreCase(method)) {
                return false; // Do NOT skip — we need to check this request
            }
        }

        // Skip all other requests — they are handled by controllers or other filters
        return true;
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

        String email = authentication.getName();
        UserEntity user = userService.findByemail(email);

        if (user == null) {
            filterChain.doFilter(request, response);
            return;
        }

        // Check if user has ROLE_SUPERVISOR
        boolean isSupervisor = hasSupervisorRole(user);

        if (!isSupervisor) {
            // Not a supervisor, let the request through
            filterChain.doFilter(request, response);
            return;
        }

        // At this point: user is a supervisor attempting POST or DELETE on /api/leads/**
        String path = request.getRequestURI();
        String method = request.getMethod();

        log.warn("Unauthorized access: userId={}, endpoint={}, method={}, leadId={}",
                user.getId(), path, method, extractLeadId(path));

        response.setStatus(HttpServletResponse.SC_FORBIDDEN);
        response.setContentType("application/json;charset=UTF-8");

        Map<String, String> errorBody = new HashMap<>();
        errorBody.put("error", "OPERATION_NOT_ALLOWED");
        errorBody.put("message", "Los supervisores solo pueden editar leads");

        response.getWriter().write(objectMapper.writeValueAsString(errorBody));
    }

    /**
     * Checks if the user has the ROLE_SUPERVISOR role.
     */
    private boolean hasSupervisorRole(UserEntity user) {
        List<RolEntity> roles = user.getRols();
        if (roles == null) {
            return false;
        }
        return roles.stream()
                .anyMatch(rol -> "ROLE_SUPERVISOR".equals(rol.getName()));
    }

    /**
     * Extracts the lead ID from the request path if present.
     * For paths like /api/leads/123, returns "123".
     * For paths like /api/leads, returns "N/A".
     */
    private String extractLeadId(String path) {
        String prefix = "/api/leads/";
        if (path.startsWith(prefix)) {
            String remainder = path.substring(prefix.length());
            // Get the first segment (could be followed by more path)
            int slashIndex = remainder.indexOf('/');
            String idPart = slashIndex > 0 ? remainder.substring(0, slashIndex) : remainder;
            try {
                Long.parseLong(idPart);
                return idPart;
            } catch (NumberFormatException e) {
                return "N/A";
            }
        }
        return "N/A";
    }
}
