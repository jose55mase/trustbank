package com.bolsadeideas.springboot.backend.apirest.config;

import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Profile;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

import javax.persistence.EntityManager;
import javax.persistence.PersistenceContext;
import java.util.Arrays;
import java.util.HashSet;

@Component
@Profile("dev")
public class DevDataLoader implements CommandLineRunner {

    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // Verificar si ya existen datos (evita duplicados en hot-reload de devtools)
        Long moduleCount = (Long) entityManager.createQuery("SELECT COUNT(m) FROM ModuleEntity m").getSingleResult();
        if (moduleCount > 0) {
            System.out.println("=== Datos de dev ya existen, omitiendo carga ===");
            return;
        }

        // Crear módulos del catálogo
        ModuleEntity modLeads = createModule("LEADS", "Leads", "Gestión de leads y prospectos", "leaderboard", 1);
        ModuleEntity modDocuments = createModule("DOCUMENTS", "Documentos", "Gestión de documentos de usuarios", "description", 2);
        ModuleEntity modDocApproval = createModule("DOCUMENT_APPROVAL", "Aprobación de Documentos", "Aprobar o rechazar documentos", "verified", 3);
        ModuleEntity modUserMgmt = createModule("USER_MANAGEMENT", "Gestión de Usuarios", "Administrar usuarios del sistema", "group", 4);
        ModuleEntity modRoleMgmt = createModule("ROLE_MANAGEMENT", "Gestión de Roles", "Administrar roles y permisos", "admin_panel_settings", 5);
        ModuleEntity modSupervisorAssignments = createModule("SUPERVISOR_ASSIGNMENTS", "Tipos de Asignación", "Gestionar tipos de asignación de supervisores", "assignment", 6);
        ModuleEntity modRequests = createModule("REQUESTS", "Solicitudes", "Ver y gestionar solicitudes de usuarios", "inbox", 7);
        ModuleEntity modAdminPanel = createModule("ADMIN_PANEL", "Panel Admin", "Acceso al panel administrativo", "dashboard", 8);

        entityManager.flush();

        // Crear roles
        RolEntity roleUser = new RolEntity();
        roleUser.setName("ROLE_USER");
        roleUser.setModules(new HashSet<>(Arrays.asList(modLeads, modDocuments)));
        entityManager.persist(roleUser);

        RolEntity roleAdmin = new RolEntity();
        roleAdmin.setName("ROLE_ADMIN");
        roleAdmin.setModules(new HashSet<>(Arrays.asList(modLeads, modDocuments, modDocApproval, modUserMgmt, modRoleMgmt, modSupervisorAssignments, modRequests, modAdminPanel)));
        entityManager.persist(roleAdmin);

        RolEntity roleSuperAdmin = new RolEntity();
        roleSuperAdmin.setName("ROLE_SUPER_ADMIN");
        roleSuperAdmin.setModules(new HashSet<>(Arrays.asList(modLeads, modDocuments, modDocApproval, modUserMgmt, modRoleMgmt, modSupervisorAssignments, modRequests, modAdminPanel)));
        entityManager.persist(roleSuperAdmin);

        RolEntity roleSupervisor = new RolEntity();
        roleSupervisor.setName("ROLE_SUPERVISOR");
        roleSupervisor.setModules(new HashSet<>(Arrays.asList(modLeads)));
        entityManager.persist(roleSupervisor);

        entityManager.flush();

        // Usuario de prueba (password: 12345)
        UserEntity user = new UserEntity();
        user.setUsername("testuser");
        user.setEmail("user@test.com");
        user.setFistName("Usuario");
        user.setLastName("Prueba");
        user.setPassword(passwordEncoder.encode("12345"));
        user.setMoneyclean(5000);
        user.setStatus(true);
        user.setAccountStatus("ACTIVE");
        user.setDocumentsAprov("{\"foto\":false,\"fromt\":false,\"back\":false}");
        user.setRols(Arrays.asList(roleUser));
        entityManager.persist(user);

        // Admin de prueba (password: 12345)
        UserEntity admin = new UserEntity();
        admin.setUsername("admin");
        admin.setEmail("admin@test.com");
        admin.setFistName("Admin");
        admin.setLastName("TrustBank");
        admin.setPassword(passwordEncoder.encode("12345"));
        admin.setMoneyclean(10000);
        admin.setStatus(true);
        admin.setAccountStatus("ACTIVE");
        admin.setDocumentsAprov("{\"foto\":false,\"fromt\":false,\"back\":false}");
        admin.setRols(Arrays.asList(roleAdmin));
        entityManager.persist(admin);

        System.out.println("=== Datos de prueba cargados ===");
        System.out.println("Usuario: user@test.com / 12345 (módulos: LEADS, DOCUMENTS)");
        System.out.println("Admin:   admin@test.com / 12345 (todos los módulos)");
        System.out.println("Roles disponibles: ROLE_USER, ROLE_ADMIN, ROLE_SUPER_ADMIN, ROLE_SUPERVISOR");
        System.out.println("================================");
    }

    private ModuleEntity createModule(String code, String name, String description, String icon, int displayOrder) {
        ModuleEntity module = new ModuleEntity();
        module.setCode(code);
        module.setName(name);
        module.setDescription(description);
        module.setIcon(icon);
        module.setDisplayOrder(displayOrder);
        entityManager.persist(module);
        return module;
    }
}
