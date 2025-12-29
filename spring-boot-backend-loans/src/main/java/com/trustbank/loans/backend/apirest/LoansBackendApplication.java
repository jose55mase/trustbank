package com.trustbank.loans.backend.apirest;

import com.trustbank.loans.backend.apirest.entity.AuthUser;
import com.trustbank.loans.backend.apirest.repository.AuthUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;
import org.springframework.security.crypto.password.PasswordEncoder;

@SpringBootApplication
@EnableScheduling
public class LoansBackendApplication implements CommandLineRunner {

	@Autowired
	private AuthUserRepository authUserRepository;
	
	@Autowired
	private PasswordEncoder passwordEncoder;

	public static void main(String[] args) {
		SpringApplication.run(LoansBackendApplication.class, args);
	}

	@Override
	public void run(String... args) throws Exception {
		// Crear usuario administrador por defecto
		if (!authUserRepository.existsByUsername("admin")) {
			AuthUser admin = new AuthUser();
			admin.setUsername("admin");
			admin.setPassword(passwordEncoder.encode("admin123"));
			admin.setEmail("admin@trustbank.com");
			authUserRepository.save(admin);
			System.out.println("Usuario administrador creado: admin/admin123");
		}
		
		System.out.println("Aplicación iniciada correctamente!");
	}
}
