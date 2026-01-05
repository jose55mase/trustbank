package com.trustbank.loans.backend.apirest.dto;

import java.time.LocalDateTime;

public class UserRequest {
    private String name;
    private String userCode;
    private String phone;
    private String direccion;
    private String referenceName;
    private String referencePhone;
    private LocalDateTime registrationDate;
    
    // Getters and Setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    
    public String getUserCode() { return userCode; }
    public void setUserCode(String userCode) { this.userCode = userCode; }
    
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    
    public String getDireccion() { return direccion; }
    public void setDireccion(String direccion) { this.direccion = direccion; }
    
    public String getReferenceName() { return referenceName; }
    public void setReferenceName(String referenceName) { this.referenceName = referenceName; }
    
    public String getReferencePhone() { return referencePhone; }
    public void setReferencePhone(String referencePhone) { this.referencePhone = referencePhone; }
    
    public LocalDateTime getRegistrationDate() { return registrationDate; }
    public void setRegistrationDate(LocalDateTime registrationDate) { this.registrationDate = registrationDate; }
}