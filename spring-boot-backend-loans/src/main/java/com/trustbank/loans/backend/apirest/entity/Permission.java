package com.trustbank.loans.backend.apirest.entity;

import javax.persistence.*;

@Entity
@Table(name = "permissions")
public class Permission {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @Column(nullable = false, unique = true, length = 50)
    private String name;
    
    @Column(length = 100)
    private String description;
    
    @Column(name = "module_key", nullable = false, unique = true, length = 50)
    private String moduleKey;
    
    public Permission() {}
    
    public Permission(String name, String description, String moduleKey) {
        this.name = name;
        this.description = description;
        this.moduleKey = moduleKey;
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public String getModuleKey() { return moduleKey; }
    public void setModuleKey(String moduleKey) { this.moduleKey = moduleKey; }
}