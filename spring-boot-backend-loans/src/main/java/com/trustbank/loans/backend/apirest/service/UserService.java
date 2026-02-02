package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.repository.UserRepository;
import com.trustbank.loans.backend.apirest.repository.LoanRepository;
import com.trustbank.loans.backend.apirest.repository.PaymentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.util.Random;

@Service
public class UserService {
    
    @Autowired
    private UserRepository userRepository;
    
    @Autowired
    private LoanRepository loanRepository;
    
    @Autowired
    private PaymentRepository paymentRepository;
    
    public List<User> findAll() {
        List<User> users = userRepository.findAllByOrderByUserCodeAsc();
        users.sort((a, b) -> {
            try {
                Integer numA = Integer.parseInt(a.getUserCode());
                Integer numB = Integer.parseInt(b.getUserCode());
                return numA.compareTo(numB);
            } catch (NumberFormatException e) {
                return a.getUserCode().compareTo(b.getUserCode());
            }
        });
        return users;
    }
    
    public Page<User> findAllPaginated(Pageable pageable) {
        return userRepository.findAll(pageable);
    }
    
    public List<User> findByUserCodeOrderedAlphabetically(String userCode) {
        return userRepository.findByUserCodeContainingIgnoreCaseOrderByUserCodeAsc(userCode);
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
    
    public User updateUser(User user, String originalUserCode) {
        // Si el código no cambió, permitir la actualización
        if (originalUserCode != null && originalUserCode.equals(user.getUserCode())) {
            return userRepository.save(user);
        }
        
        // Si el código cambió, validar que el nuevo código no exista
        if (userRepository.existsByUserCode(user.getUserCode())) {
            throw new RuntimeException("El código de usuario ya existe: " + user.getUserCode());
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
        // Verificar si el usuario existe
        User user = userRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado con ID: " + id));
        
        // Eliminar todos los pagos asociados
        List<com.trustbank.loans.backend.apirest.entity.Payment> payments = paymentRepository.findByUserId(id);
        if (!payments.isEmpty()) {
            paymentRepository.deleteAll(payments);
        }
        
        // Eliminar todos los préstamos asociados
        List<com.trustbank.loans.backend.apirest.entity.Loan> loans = loanRepository.findByUserId(id);
        if (!loans.isEmpty()) {
            loanRepository.deleteAll(loans);
        }
        
        // Finalmente eliminar el usuario
        userRepository.deleteById(id);
    }
    
    private boolean hasRelatedLoans(Long userId) {
        List<com.trustbank.loans.backend.apirest.entity.Loan> loans = loanRepository.findByUserId(userId);
        return !loans.isEmpty();
    }
    
    private boolean hasRelatedPayments(Long userId) {
        List<com.trustbank.loans.backend.apirest.entity.Payment> payments = paymentRepository.findByUserId(userId);
        return !payments.isEmpty();
    }
}