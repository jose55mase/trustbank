package com.bolsadeideas.springboot.backend.apirest.models.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "credits")
public class CreditEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "credit_type")
    private String creditType;

    @Column(name = "amount")
    private Double amount;

    @Column(name = "term_months")
    private Integer termMonths;

    @Column(name = "interest_rate")
    private Double interestRate;

    @Column(name = "monthly_payment")
    private Double monthlyPayment;

    @Column(name = "status")
    private String status = "PENDING";

    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    @Column(name = "approved_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date approvedAt;

    private static final long serialVersionUID = 1L;

    public CreditEntity() {
        this.createdAt = new Date();
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getCreditType() { return creditType; }
    public void setCreditType(String creditType) { this.creditType = creditType; }

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }

    public Integer getTermMonths() { return termMonths; }
    public void setTermMonths(Integer termMonths) { this.termMonths = termMonths; }

    public Double getInterestRate() { return interestRate; }
    public void setInterestRate(Double interestRate) { this.interestRate = interestRate; }

    public Double getMonthlyPayment() { return monthlyPayment; }
    public void setMonthlyPayment(Double monthlyPayment) { this.monthlyPayment = monthlyPayment; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getApprovedAt() { return approvedAt; }
    public void setApprovedAt(Date approvedAt) { this.approvedAt = approvedAt; }
}