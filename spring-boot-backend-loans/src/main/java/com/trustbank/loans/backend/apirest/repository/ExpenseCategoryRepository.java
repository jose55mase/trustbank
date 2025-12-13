package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.ExpenseCategory;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface ExpenseCategoryRepository extends JpaRepository<ExpenseCategory, Long> {
    
    Optional<ExpenseCategory> findByName(String name);
    
    boolean existsByName(String name);
}