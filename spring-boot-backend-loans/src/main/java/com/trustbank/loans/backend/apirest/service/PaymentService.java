package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Payment;
import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.repository.PaymentRepository;
import com.trustbank.loans.backend.apirest.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class PaymentService {
    
    @Autowired
    private PaymentRepository paymentRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    public List<Payment> findAll() {
        return paymentRepository.findAllByOrderByPaymentDateDesc();
    }
    
    public Optional<Payment> findById(Long id) {
        return paymentRepository.findById(id);
    }
    
    public List<Payment> findByUserId(Long userId) {
        return paymentRepository.findByUserId(userId);
    }
    
    public Payment save(Payment payment) {
        // Asegurar que el usuario existe
        if (payment.getUser() != null && payment.getUser().getId() != null) {
            Optional<User> user = userRepository.findById(payment.getUser().getId());
            if (user.isPresent()) {
                payment.setUser(user.get());
            } else {
                throw new RuntimeException("Usuario no encontrado con ID: " + payment.getUser().getId());
            }
        }
        
        // Si es un pago menor a cuota, agregar nota en la descripción
        if (payment.getPagoMenorACuota() != null && payment.getPagoMenorACuota()) {
            String currentDescription = payment.getDescription() != null ? payment.getDescription() : "";
            if (!currentDescription.contains("- Pago parcial")) {
                payment.setDescription(currentDescription + " - Pago parcial");
            }
        }
        
        return paymentRepository.save(payment);
    }
    
    public void deleteById(Long id) {
        paymentRepository.deleteById(id);
    }
    
    // Tarea programada para eliminar pagos registrados con más de 15 días
    @Scheduled(cron = "0 0 2 * * ?") // Ejecutar diariamente a las 2:00 AM
    public void deleteOldRegisteredPayments() {
        LocalDateTime cutoffDate = LocalDateTime.now().minusDays(15);
        List<Payment> oldPayments = paymentRepository.findByRegisteredTrueAndPaymentDateBefore(cutoffDate);
        
        if (!oldPayments.isEmpty()) {
            paymentRepository.deleteAll(oldPayments);
            System.out.println("Eliminados " + oldPayments.size() + " pagos registrados con más de 15 días");
        }
    }
}