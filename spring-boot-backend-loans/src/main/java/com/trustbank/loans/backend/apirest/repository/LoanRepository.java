package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Loan;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface LoanRepository extends JpaRepository<Loan, Long> {
    
    List<Loan> findByUserId(Long userId);
    
    @Query("SELECT SUM(l.amount) FROM Loan l WHERE l.status = 'ACTIVE'")
    Double getTotalActiveLoanAmount();
}