package com.trustbank.loans.backend.apirest.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import javax.persistence.*;
import static com.trustbank.loans.backend.apirest.entity.LoanStatus.*;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "loans")
public class Loan {
    
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    
    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;
    
    @Column(nullable = false, precision = 15, scale = 2)
    private BigDecimal amount;
    
    @Column(name = "interest_rate", nullable = false, precision = 5, scale = 2)
    private BigDecimal interestRate;
    
    @Column(nullable = false)
    private Integer installments;
    
    @Column(name = "paid_installments", nullable = false)
    private Integer paidInstallments = 0;
    
    @Column(name = "start_date", nullable = false)
    private LocalDateTime startDate;
    
    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 20)
    private LoanStatus status;
    
    @Enumerated(EnumType.STRING)
    @Column(name = "previous_status", length = 20)
    private LoanStatus previousStatus;
    
    @Column(name = "status_change_date")
    private LocalDateTime statusChangeDate;
    
    @Column(name = "pago_anterior")
    private Boolean pagoAnterior = false;
    
    @Column(name = "pago_actual")
    private Boolean pagoActual = false;
    
    @OneToMany(mappedBy = "loan", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JsonIgnore
    private List<Transaction> transactions;
    
    public Loan() {
        this.startDate = LocalDateTime.now();
        this.status = LoanStatus.ACTIVE;
    }
    
    // Calculated fields
    public BigDecimal getTotalAmount() {
        return amount.add(amount.multiply(interestRate).divide(BigDecimal.valueOf(100)));
    }
    
    public BigDecimal getInstallmentAmount() {
        return getTotalAmount().divide(BigDecimal.valueOf(installments), 2, BigDecimal.ROUND_HALF_UP);
    }
    
    public BigDecimal getRemainingAmount() {
        return getInstallmentAmount().multiply(BigDecimal.valueOf(installments - paidInstallments));
    }
    
    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }
    
    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }
    
    public BigDecimal getAmount() { return amount; }
    public void setAmount(BigDecimal amount) { this.amount = amount; }
    
    public BigDecimal getInterestRate() { return interestRate; }
    public void setInterestRate(BigDecimal interestRate) { this.interestRate = interestRate; }
    
    public Integer getInstallments() { return installments; }
    public void setInstallments(Integer installments) { this.installments = installments; }
    
    public Integer getPaidInstallments() { return paidInstallments; }
    public void setPaidInstallments(Integer paidInstallments) { this.paidInstallments = paidInstallments; }
    
    public LocalDateTime getStartDate() { return startDate; }
    public void setStartDate(LocalDateTime startDate) { this.startDate = startDate; }
    
    public LoanStatus getStatus() { return status; }
    public void setStatus(LoanStatus status) { 
        if (this.status != null && !this.status.equals(status)) {
            this.previousStatus = this.status;
            this.statusChangeDate = LocalDateTime.now();
        }
        this.status = status; 
    }
    
    public LoanStatus getPreviousStatus() { return previousStatus; }
    public void setPreviousStatus(LoanStatus previousStatus) { this.previousStatus = previousStatus; }
    
    public LocalDateTime getStatusChangeDate() { return statusChangeDate; }
    public void setStatusChangeDate(LocalDateTime statusChangeDate) { this.statusChangeDate = statusChangeDate; }
    
    public List<Transaction> getTransactions() { return transactions; }
    public void setTransactions(List<Transaction> transactions) { this.transactions = transactions; }
    
    public Boolean getPagoAnterior() { return pagoAnterior; }
    public void setPagoAnterior(Boolean pagoAnterior) { this.pagoAnterior = pagoAnterior; }
    
    public Boolean getPagoActual() { return pagoActual; }
    public void setPagoActual(Boolean pagoActual) { this.pagoActual = pagoActual; }
}