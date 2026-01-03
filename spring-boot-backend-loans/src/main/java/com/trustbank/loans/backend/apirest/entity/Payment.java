package com.trustbank.loans.backend.apirest.entity;

import javax.persistence.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "payments")
public class Payment {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;
    
    @Column(name = "payment_method", nullable = false, length = 50)
    private String paymentMethod;
    
    @Column(length = 500)
    private String description;
    
    @Column(name = "debt_payment", nullable = false, precision = 15, scale = 2)
    private BigDecimal debtPayment;
    
    @Column(name = "interest_payment", nullable = false, precision = 15, scale = 2)
    private BigDecimal interestPayment;
    
    @Column(name = "payment_date", nullable = false)
    private LocalDateTime paymentDate;
    
    @Column(name = "registered", nullable = false)
    private Boolean registered;
    
    @Column(name = "salida", nullable = false)
    private Boolean salida;
    
    public Payment() {
        this.paymentDate = LocalDateTime.now();
        this.registered = false; // Por defecto sin registrar
        this.salida = false; // Por defecto no es salida
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    
    public String getPaymentMethod() { return paymentMethod; }
    public void setPaymentMethod(String paymentMethod) { this.paymentMethod = paymentMethod; }
    
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    
    public BigDecimal getDebtPayment() { return debtPayment; }
    public void setDebtPayment(BigDecimal debtPayment) { this.debtPayment = debtPayment; }
    
    public BigDecimal getInterestPayment() { return interestPayment; }
    public void setInterestPayment(BigDecimal interestPayment) { this.interestPayment = interestPayment; }
    
    public LocalDateTime getPaymentDate() { return paymentDate; }
    public void setPaymentDate(LocalDateTime paymentDate) { this.paymentDate = paymentDate; }
    
    public Boolean getRegistered() { return registered; }
    public void setRegistered(Boolean registered) { this.registered = registered; }
    
    public Boolean getSalida() { return salida; }
    public void setSalida(Boolean salida) { this.salida = salida; }
}