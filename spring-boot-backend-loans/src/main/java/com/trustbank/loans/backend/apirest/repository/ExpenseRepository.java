package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Expense;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface ExpenseRepository extends JpaRepository<Expense, Long> {
    
    List<Expense> findByExpenseDateBetween(LocalDateTime startDate, LocalDateTime endDate);
    
    @Query("SELECT e FROM Expense e WHERE e.category.id = :categoryId ORDER BY e.expenseDate DESC")
    List<Expense> findByCategoryId(@Param("categoryId") Long categoryId);
    
    @Query("SELECT e FROM Expense e ORDER BY e.expenseDate DESC")
    List<Expense> findAllOrderByExpenseDateDesc();
}