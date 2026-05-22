package com.bolsadeideas.springboot.backend.apirest.config;

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
        // Crear roles
        RolEntity roleUser = new RolEntity();
        roleUser.setName("ROLE_USER");
        entityManager.persist(roleUser);

        RolEntity roleAdmin = new RolEntity();
        roleAdmin.setName("ROLE_ADMIN");
        entityManager.persist(roleAdmin);

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
        System.out.println("Usuario: user@test.com / 12345");
        System.out.println("Admin:   admin@test.com / 12345");
        System.out.println("================================");
    }
}
