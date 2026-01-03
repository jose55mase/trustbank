package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.time.LocalDateTime;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    List<Transaction> findByLoanIdOrderByDateDesc(Long loanId);
    
    @Query("SELECT SUM(t.amount) FROM Transaction t WHERE t.type = 'PAYMENT'")
    Double getTotalPayments();
    
    List<Transaction> findByDateBetweenOrderByDateDesc(LocalDateTime startDate, LocalDateTime endDate);
    
    @Query("SELECT t FROM Transaction t ORDER BY t.date DESC")
    List<Transaction> findAllOrderByDateDesc();
}