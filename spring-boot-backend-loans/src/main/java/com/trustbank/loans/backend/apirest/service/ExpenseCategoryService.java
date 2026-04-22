package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.ExpenseCategory;
import com.trustbank.loans.backend.apirest.repository.ExpenseCategoryRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.cache.annotation.CacheEvict;
import org.springframework.cache.annotation.Cacheable;
import org.springframework.cache.annotation.Caching;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class ExpenseCategoryService {
    
    @Autowired
    private ExpenseCategoryRepository expenseCategoryRepository;
    
    @Cacheable(value = "expense_categories")
    public List<ExpenseCategory> findAll() {
        return expenseCategoryRepository.findAll();
    }
    
    public Optional<ExpenseCategory> findById(Long id) {
        return expenseCategoryRepository.findById(id);
    }
    
    @CacheEvict(value = "expense_categories", allEntries = true)
    public ExpenseCategory save(ExpenseCategory category) {
        if (expenseCategoryRepository.existsByName(category.getName())) {
            throw new RuntimeException("Ya existe una categoría con ese nombre");
        }
        return expenseCategoryRepository.save(category);
    }
    
    @CacheEvict(value = "expense_categories", allEntries = true)
    public ExpenseCategory update(Long id, ExpenseCategory categoryDetails) {
        ExpenseCategory category = expenseCategoryRepository.findById(id)
                .orElseThrow(() -> new RuntimeException("Categoría no encontrada"));
        
        // Verificar si el nuevo nombre ya existe (excepto para la misma categoría)
        if (!category.getName().equals(categoryDetails.getName()) && 
            expenseCategoryRepository.existsByName(categoryDetails.getName())) {
            throw new RuntimeException("Ya existe una categoría con ese nombre");
        }
        
        category.setName(categoryDetails.getName());
        category.setIconName(categoryDetails.getIconName());
        category.setColorValue(categoryDetails.getColorValue());
        
        return expenseCategoryRepository.save(category);
    }
    
    @CacheEvict(value = "expense_categories", allEntries = true)
    public void deleteById(Long id) {
            throw new RuntimeException("Categoría no encontrada");
        }
        expenseCategoryRepository.deleteById(id);
    }
}