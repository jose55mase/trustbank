package com.trustbank.loans.backend.apirest.entity;

import javax.persistence.*;
import java.time.LocalDateTime;

@Entity
@Table(name = "expense_categories")
public class ExpenseCategory {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true)
    private String name;
    
    @Column(nullable = false)
    private String iconName;
    
    @Column(nullable = false)
    private String colorValue;
    
    @Column(nullable = false)
    private LocalDateTime createdAt;
    
    public ExpenseCategory() {
        this.createdAt = LocalDateTime.now();
    }
    
    public ExpenseCategory(String name, String iconName, String colorValue) {
        this();
        this.name = name;
        this.iconName = iconName;
        this.colorValue = colorValue;
    }
    
    // Getters y Setters
    public Long getId() {
        return id;
    }
    
    public void setId(Long id) {
        this.id = id;
    }
    
    public String getName() {
        return name;
    }
    
    public void setName(String name) {
        this.name = name;
    }
    
    public String getIconName() {
        return iconName;
    }
    
    public void setIconName(String iconName) {
        this.iconName = iconName;
    }
    
    public String getColorValue() {
        return colorValue;
    }
    
    public void setColorValue(String colorValue) {
        this.colorValue = colorValue;
    }
    
    public LocalDateTime getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}