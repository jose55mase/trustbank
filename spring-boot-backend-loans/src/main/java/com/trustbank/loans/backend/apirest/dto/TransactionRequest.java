package com.trustbank.loans.backend.apirest.dto;

import com.trustbank.loans.backend.apirest.entity.PaymentMethod;
import com.trustbank.loans.backend.apirest.entity.TransactionType;
import java.math.BigDecimal;

public class TransactionRequest {
    private TransactionType type;
    private LoanRef loan;
    private BigDecimal amount;
    private PaymentMethod paymentMethod;
    private String notes;
    private BigDecimal interestAmount;
    private BigDecimal principalAmount;
    
    public static class LoanRef {
        private Long id;
        
        public Long getId() { return id; }
        public void setId(Long id) { this.id = id; }
    }
    
    // Getters and Setters
    public TransactionType getType() { return type; }
    public void setType(TransactionType type) { this.type = type; }
    
    public LoanRef getLoan() { return loan; }
    public void setLoan(LoanRef loan) { this.loan = loan; }
    
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    
    public PaymentMethod getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(PaymentMethod paymentMethod) { this.paymentMethod = paymentMethod; }
    
    public String getNotes() { return notes; }
    public void setNotes(String notes) { this.notes = notes; }
    
    public BigDecimal getInterestAmount() { return interestAmount; }
    public void setInterestAmount(BigDecimal interestAmount) { this.interestAmount = interestAmount; }
    
    public BigDecimal getPrincipalAmount() { return principalAmount; }
    public void setPrincipalAmount(BigDecimal principalAmount) { this.principalAmount = principalAmount; }
}