package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Expense;
import com.trustbank.loans.backend.apirest.entity.ExpenseCategory;
import com.trustbank.loans.backend.apirest.repository.ExpenseRepository;
import com.trustbank.loans.backend.apirest.repository.ExpenseCategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class ExpenseService {
    
    @Autowired
    private ExpenseRepository expenseRepository;
    
    @Autowired
    private ExpenseCategoryRepository expenseCategoryRepository;
    
    public List<Expense> findAll() {
        return expenseRepository.findAllOrderByExpenseDateDesc();
    }
    
    public Optional<Expense> findById(Long id) {
        return expenseRepository.findById(id);
    }
    
    public List<Expense> findByDateRange(LocalDateTime startDate, LocalDateTime endDate) {
        return expenseRepository.findByExpenseDateBetween(startDate, endDate);
    }
    
    public List<Expense> findByCategoryId(Long categoryId) {
        return expenseRepository.findByCategoryId(categoryId);
    }
    
    public Expense save(Expense expense) {
        // Validar que la categoría existe
        if (expense.getCategory() == null || expense.getCategory().getId() == null) {
            throw new RuntimeException("La categoría es requerida");
        }
        
        ExpenseCategory category = expenseCategoryRepository.findById(expense.getCategory().getId())
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));
        
        expense.setCategory(category);
        return expenseRepository.save(expense);
    }
    
    public Expense update(Long id, Expense expenseDetails) {
        Expense expense = expenseRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Gasto no encontrado"));
        
        if (expenseDetails.getCategory() != null && expenseDetails.getCategory().getId() != null) {
            ExpenseCategory category = expenseCategoryRepository.findById(expenseDetails.getCategory().getId())
                    .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));
            expense.setCategory(category);
        }
        
        expense.setAmount(expenseDetails.getAmount());
        expense.setDescription(expenseDetails.getDescription());
        expense.setExpenseDate(expenseDetails.getExpenseDate());
        
        return expenseRepository.save(expense);
    }
    
    public void deleteById(Long id) {
        if (!expenseRepository.existsById(id)) {
            throw new RuntimeException("Gasto no encontrado");
        }
        expenseRepository.deleteById(id);
    }
}