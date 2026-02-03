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
    
    @Column(name = "loan_type", length = 50)
    private String loanType;
    
    @Column(name = "payment_frequency", length = 50)
    private String paymentFrequency;
    
    @Column(name = "valor_real_cuota", precision = 15, scale = 2)
    private BigDecimal valorRealCuota;
    
    @Column(name = "sin_cuotas")
    private Boolean sinCuotas = false;
    
    @Column(name = "next_payment_date")
    private LocalDateTime nextPaymentDate;
    
    @OneToMany(mappedBy = "loan", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    @JsonIgnore
    private List<Transaction> transactions;
    
    public Loan() {
        // La fecha de inicio se establecerá manualmente o por defecto será la fecha actual
        if (this.startDate == null) {
            this.startDate = LocalDateTime.now();
        }
        this.status = LoanStatus.ACTIVE;
    }
    
    // Calculated fields
    public BigDecimal getTotalAmount() {
        if ("Fijo".equals(loanType)) {
            // Para préstamos fijos: monto + (monto * tasa de interés / 100 * cantidad de cuotas)
            BigDecimal interestPerInstallment = amount.multiply(interestRate).divide(BigDecimal.valueOf(100));
            BigDecimal totalInterest = interestPerInstallment.multiply(BigDecimal.valueOf(installments));
            return amount.add(totalInterest);
        } else {
            // Para otros tipos: monto + (monto * tasa de interés / 100)
            return amount.add(amount.multiply(interestRate).divide(BigDecimal.valueOf(100)));
        }
    }
    
    public BigDecimal getInstallmentAmount() {
        if ("Fijo".equals(loanType)) {
            // Para préstamos fijos: valor por cuota es la tasa de interés mensual
            return amount.multiply(interestRate).divide(BigDecimal.valueOf(100), 2, BigDecimal.ROUND_HALF_UP);
        } else {
            // Para otros tipos: total dividido entre cuotas
            return getTotalAmount().divide(BigDecimal.valueOf(installments), 2, BigDecimal.ROUND_HALF_UP);
        }
    }
    
    public BigDecimal getRemainingAmount() {
        // Calcular el total pagado en capital desde las transacciones
        // Solo se resta el principalAmount (capital), NO los intereses
        BigDecimal totalPrincipalPaid = BigDecimal.ZERO;
        if (transactions != null && !transactions.isEmpty()) {
            totalPrincipalPaid = transactions.stream()
                .filter(t -> t.getPrincipalAmount() != null && t.getPrincipalAmount().compareTo(BigDecimal.ZERO) > 0)
                .map(Transaction::getPrincipalAmount)
                .reduce(BigDecimal.ZERO, BigDecimal::add);
        }
        
        // El monto restante es el monto original menos SOLO el capital pagado
        // Los intereses se registran por separado y no afectan el saldo del préstamo
        BigDecimal remaining = amount.subtract(totalPrincipalPaid);
        return remaining.compareTo(BigDecimal.ZERO) < 0 ? BigDecimal.ZERO : remaining;
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
    
    public String getLoanType() { return loanType; }
    public void setLoanType(String loanType) { this.loanType = loanType; }
    
    public String getPaymentFrequency() { return paymentFrequency; }
    public void setPaymentFrequency(String paymentFrequency) { this.paymentFrequency = paymentFrequency; }
    
    public BigDecimal getValorRealCuota() { return valorRealCuota; }
    public void setValorRealCuota(BigDecimal valorRealCuota) { this.valorRealCuota = valorRealCuota; }
    
    public Boolean getSinCuotas() { return sinCuotas; }
    public void setSinCuotas(Boolean sinCuotas) { this.sinCuotas = sinCuotas; }
    
    public LocalDateTime getNextPaymentDate() { return nextPaymentDate; }
    public void setNextPaymentDate(LocalDateTime nextPaymentDate) { this.nextPaymentDate = nextPaymentDate; }
}