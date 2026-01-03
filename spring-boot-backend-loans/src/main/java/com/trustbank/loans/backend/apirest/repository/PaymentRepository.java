package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Payment;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface PaymentRepository extends JpaRepository<Payment, Long> {
    
    List<Payment> findByUserId(Long userId);
    
    List<Payment> findAllByOrderByPaymentDateDesc();
    
    List<Payment> findByRegisteredTrueAndPaymentDateBefore(LocalDateTime date);
}