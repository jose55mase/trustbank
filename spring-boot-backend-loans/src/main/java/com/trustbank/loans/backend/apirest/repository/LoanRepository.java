package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface LoanRepository extends JpaRepository<Loan, Long> {
    
    List<Loan> findByUserId(Long userId);
    
    List<Loan> findAllByOrderByIdDesc();
    
    List<Loan> findByStatus(LoanStatus status);
    
    Long countByStatus(LoanStatus status);
    
    @Query("SELECT SUM(l.amount) FROM Loan l WHERE l.status = 'ACTIVE'")
    Double getTotalActiveLoanAmount();
}