package com.bolsadeideas.springboot.backend.apirest.controllers;

import net.jqwik.api.*;
import net.jqwik.api.constraints.*;
import org.springframework.security.access.annotation.Secured;
import org.springframework.web.bind.annotation.*;

import java.lang.reflect.Method;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Feature: admin-excel-leads-module, Property 9: Control de acceso
 *
 * Para cualquier solicitud HTTP al módulo de leads, el sistema debe permitir el acceso
 * si y solo si el token de autenticación corresponde a un usuario con rol de administrador.
 * Cualquier solicitud sin token válido o con rol insuficiente debe ser rechazada con código 403.
 *
 * **Validates: Requirements 8.1, 8.3**
 */
class LeadControllerAccessControlPropertyTest {

    private static final String REQUIRED_ROLE = "ROLE_ADMIN";

    /**
     * Gets all public endpoint methods from LeadController (methods annotated with
     * @GetMapping, @PostMapping, @PutMapping, @DeleteMapping, or @RequestMapping).
     */
    private List<Method> getEndpointMethods() {
        return Arrays.stream(LeadController.class.getDeclaredMethods())
                .filter(method -> 
                    method.isAnnotationPresent(GetMapping.class) ||
                    method.isAnnotationPresent(PostMapping.class) ||
                    method.isAnnotationPresent(PutMapping.class) ||
                    method.isAnnotationPresent(DeleteMapping.class) ||
                    method.isAnnotationPresent(RequestMapping.class))
                .collect(Collectors.toList());
    }

    // ========== Property: All endpoint methods have @Secured annotation ==========

    @Property(tries = 1)
    @Label("Todos los endpoints del LeadController tienen la anotación @Secured")
    void allEndpointsHaveSecuredAnnotation() {
        List<Method> endpointMethods = getEndpointMethods();

        assertThat(endpointMethods)
                .as("LeadController debe tener al menos un endpoint")
                .isNotEmpty();

        for (Method method : endpointMethods) {
            assertThat(method.isAnnotationPresent(Secured.class))
                    .as("El método '%s' debe tener la anotación @Secured", method.getName())
                    .isTrue();
        }
    }

    // ========== Property: All @Secured annotations require ROLE_ADMIN ==========

    @Property(tries = 1)
    @Label("Todos los endpoints del LeadController requieren ROLE_ADMIN")
    void allEndpointsRequireAdminRole() {
        List<Method> endpointMethods = getEndpointMethods();

        assertThat(endpointMethods)
                .as("LeadController debe tener al menos un endpoint")
                .isNotEmpty();

        for (Method method : endpointMethods) {
            Secured secured = method.getAnnotation(Secured.class);
            assertThat(secured)
                    .as("El método '%s' debe tener @Secured", method.getName())
                    .isNotNull();

            String[] roles = secured.value();
            assertThat(roles)
                    .as("El método '%s' debe requerir exactamente ROLE_ADMIN", method.getName())
                    .containsExactly(REQUIRED_ROLE);
        }
    }

    // ========== Property: Only ROLE_ADMIN matches the required role ==========

    @Property(tries = 100)
    @Label("Solo el rol ROLE_ADMIN es aceptado por la configuración de seguridad del controlador")
    void onlyAdminRoleIsAccepted(@ForAll("randomRoleStrings") String role) {
        List<Method> endpointMethods = getEndpointMethods();

        for (Method method : endpointMethods) {
            Secured secured = method.getAnnotation(Secured.class);
            assertThat(secured).isNotNull();

            String[] allowedRoles = secured.value();
            boolean roleIsAllowed = Arrays.asList(allowedRoles).contains(role);

            if (role.equals(REQUIRED_ROLE)) {
                assertThat(roleIsAllowed)
                        .as("ROLE_ADMIN debe ser aceptado en el método '%s'", method.getName())
                        .isTrue();
            } else {
                assertThat(roleIsAllowed)
                        .as("El rol '%s' NO debe ser aceptado en el método '%s'", role, method.getName())
                        .isFalse();
            }
        }
    }

    // ========== Property: Random roles that are not ROLE_ADMIN are always rejected ==========

    @Property(tries = 100)
    @Label("Roles aleatorios distintos de ROLE_ADMIN son siempre rechazados")
    void nonAdminRolesAreAlwaysRejected(@ForAll("nonAdminRoles") String role) {
        List<Method> endpointMethods = getEndpointMethods();

        for (Method method : endpointMethods) {
            Secured secured = method.getAnnotation(Secured.class);
            assertThat(secured).isNotNull();

            String[] allowedRoles = secured.value();
            boolean roleIsAllowed = Arrays.asList(allowedRoles).contains(role);

            assertThat(roleIsAllowed)
                    .as("El rol '%s' NO debe ser aceptado en el método '%s'", role, method.getName())
                    .isFalse();
        }
    }

    // ========== Providers ==========

    @Provide
    Arbitrary<String> randomRoleStrings() {
        Arbitrary<String> commonRoles = Arbitraries.of(
                "ROLE_ADMIN",
                "ROLE_USER",
                "ROLE_MODERATOR",
                "ROLE_GUEST",
                "ROLE_MANAGER",
                "ROLE_OPERATOR",
                "ROLE_VIEWER",
                "ADMIN",
                "USER",
                "admin",
                "role_admin",
                "Role_Admin",
                "ROLE_SUPERADMIN",
                "ROLE_ADMIN_READONLY",
                ""
        );

        Arbitrary<String> randomStrings = Arbitraries.strings()
                .alpha()
                .ofMinLength(1)
                .ofMaxLength(30)
                .map(s -> "ROLE_" + s.toUpperCase());

        return Arbitraries.frequencyOf(
                Tuple.of(3, commonRoles),
                Tuple.of(7, randomStrings)
        );
    }

    @Provide
    Arbitrary<String> nonAdminRoles() {
        Arbitrary<String> commonNonAdminRoles = Arbitraries.of(
                "ROLE_USER",
                "ROLE_MODERATOR",
                "ROLE_GUEST",
                "ROLE_MANAGER",
                "ROLE_OPERATOR",
                "ROLE_VIEWER",
                "ADMIN",
                "USER",
                "admin",
                "role_admin",
                "Role_Admin",
                "ROLE_SUPERADMIN",
                "ROLE_ADMIN_READONLY",
                "ROLE_ADMIN_WRITE",
                ""
        );

        Arbitrary<String> randomNonAdminStrings = Arbitraries.strings()
                .alpha()
                .ofMinLength(1)
                .ofMaxLength(30)
                .filter(s -> !("ROLE_" + s.toUpperCase()).equals(REQUIRED_ROLE))
                .map(s -> "ROLE_" + s.toUpperCase());

        return Arbitraries.frequencyOf(
                Tuple.of(3, commonNonAdminRoles),
                Tuple.of(7, randomNonAdminStrings)
        );
    }
}
