package com.trustbank.loans.backend.apirest.dto;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class LoanRequest {
    private UserReference user;
    private BigDecimal amount;
    private BigDecimal interestRate;
    private Integer installments;
    private String loanType;
    private String paymentFrequency;
    private LocalDateTime startDate;
    
    // Nested class for user reference
    public static class UserReference {
        private Long id;
        
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
    }
    
    // Getters and Setters
    public UserReference getUser() { return user; }
    public void setUser(UserReference user) { this.user = user; }
    
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    
    public BigDecimal getInterestRate() { return interestRate; }
    public void setInterestRate(BigDecimal interestRate) { this.interestRate = interestRate; }
    
    public Integer getInstallments() { return installments; }
    public void setInstallments(Integer installments) { this.installments = installments; }
    
    public String getLoanType() { return loanType; }
    public void setLoanType(String loanType) { this.loanType = loanType; }
    
    public String getPaymentFrequency() { return paymentFrequency; }
    public void setPaymentFrequency(String paymentFrequency) { this.paymentFrequency = paymentFrequency; }
    
    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }
}