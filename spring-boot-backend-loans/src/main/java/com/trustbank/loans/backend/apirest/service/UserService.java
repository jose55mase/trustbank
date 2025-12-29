package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.Random;

@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    public List<User> findAll() {
        return userRepository.findAllByOrderByRegistrationDateDesc();
    }
    
    public Optional<User> findById(Long id) {
        return userRepository.findById(id);
    }
    
    public User save(User user) {
        if (user.getUserCode() == null || user.getUserCode().isEmpty()) {
            user.setUserCode(generateUserCode());
        } else {
            // Validar que el código no exista
            if (userRepository.existsByUserCode(user.getUserCode())) {
                throw new RuntimeException("El código de usuario ya existe: " + user.getUserCode());
            }
        }
        return userRepository.save(user);
    }
    
    private String generateUserCode() {
        String code;
        do {
            code = "USR" + String.format("%04d", new Random().nextInt(10000));
        } while (userRepository.existsByUserCode(code));
        return code;
    }
    
    public void deleteById(Long id) {
        userRepository.deleteById(id);
    }
}