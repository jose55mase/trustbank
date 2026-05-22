package com.bolsadeideas.springboot.backend.apirest.config;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.RolDao;
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
@Profile("prod")
public class ProdDataLoader implements CommandLineRunner {

    @PersistenceContext
    private EntityManager entityManager;

    @Autowired
    private BCryptPasswordEncoder passwordEncoder;

    @Autowired
    private IUserDao userDao;

    @Override
    @Transactional
    public void run(String... args) throws Exception {
        // Solo insertar si no existen usuarios (evita duplicados en reinicios)
        if (userDao.findByUsername("testuser") != null || userDao.findByUsername("admin") != null) {
            System.out.println("=== Usuarios de producción ya existen, omitiendo carga ===");
            return;
        }

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
        user.setEmail("user@trustbank.com");
        user.setFistName("Usuario");
        user.setLastName("Prueba");
        user.setPassword(passwordEncoder.encode("12345"));
        user.setMoneyclean(5000);
        user.setStatus(true);
        user.setAccountStatus("ACTIVE");
        user.setDocumentsAprov("{\"foto\":false,\"fromt\":false,\"back\":false}");
        user.setRols(Arrays.asList(roleUser));
        entityManager.persist(user);

        // Administrador (password: 12345)
        UserEntity admin = new UserEntity();
        admin.setUsername("admin");
        admin.setEmail("admin@trustbank.com");
        admin.setFistName("Admin");
        admin.setLastName("TrustBank");
        admin.setPassword(passwordEncoder.encode("12345"));
        admin.setMoneyclean(10000);
        admin.setStatus(true);
        admin.setAccountStatus("ACTIVE");
        admin.setDocumentsAprov("{\"foto\":false,\"fromt\":false,\"back\":false}");
        admin.setRols(Arrays.asList(roleAdmin));
        entityManager.persist(admin);

        System.out.println("=== Usuarios de producción cargados ===");
        System.out.println("Usuario: user@trustbank.com / 12345 (ROLE_USER)");
        System.out.println("Admin:   admin@trustbank.com / 12345 (ROLE_ADMIN)");
        System.out.println("========================================");
    }
}
