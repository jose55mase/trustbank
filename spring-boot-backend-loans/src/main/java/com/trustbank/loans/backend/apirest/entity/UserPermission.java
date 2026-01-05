package com.trustbank.loans.backend.apirest.entity;

import javax.persistence.*;

@Entity
@Table(name = "user_permissions")
public class UserPermission {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "auth_user_id", nullable = false)
    private AuthUser authUser;
    
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "permission_id", nullable = false)
    private Permission permission;
    
    @Column(nullable = false)
    private Boolean granted = true;
    
    public UserPermission() {}
    
    public UserPermission(AuthUser authUser, Permission permission, Boolean granted) {
        this.authUser = authUser;
        this.permission = permission;
        this.granted = granted;
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public AuthUser getAuthUser() { return authUser; }
    public void setAuthUser(AuthUser authUser) { this.authUser = authUser; }
    
    public Permission getPermission() { return permission; }
    public void setPermission(Permission permission) { this.permission = permission; }
    
    public Boolean getGranted() { return granted; }
    public void setGranted(Boolean granted) { this.granted = granted; }
}