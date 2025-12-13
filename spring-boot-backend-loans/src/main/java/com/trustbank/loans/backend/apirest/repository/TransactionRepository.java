package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Transaction;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.time.LocalDateTime;

@Repository
public interface TransactionRepository extends JpaRepository<Transaction, Long> {
    
    List<Transaction> findByLoanId(Long loanId);
    
    @Query("SELECT SUM(t.amount) FROM Transaction t WHERE t.type = 'PAYMENT'")
    Double getTotalPayments();
    
    List<Transaction> findByDateBetween(LocalDateTime startDate, LocalDateTime endDate);
}