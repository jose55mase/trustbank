package com.bolsadeideas.springboot.backend.apirest.models.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "admin_requests")
public class AdminRequestEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "request_type")
    private String requestType; // SEND_MONEY, RECHARGE, CREDIT

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "amount")
    private Double amount;

    @Column(name = "details")
    private String details;

    @Column(name = "status")
    private String status; // PENDING, APPROVED, REJECTED

    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    @Column(name = "processed_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date processedAt;

    @Column(name = "admin_notes")
    private String adminNotes;

    private static final long serialVersionUID = 1L;

    public AdminRequestEntity() {
        this.createdAt = new Date();
        this.status = "PENDING";
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getRequestType() { return requestType; }
    public void setRequestType(String requestType) { this.requestType = requestType; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public Double getAmount() { return amount; }
    public void setAmount(Double amount) { this.amount = amount; }

    public String getDetails() { return details; }
    public void setDetails(String details) { this.details = details; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getCreatedAt() { return createdAt; }
    public void setCreatedAt(Date createdAt) { this.createdAt = createdAt; }

    public Date getProcessedAt() { return processedAt; }
    public void setProcessedAt(Date processedAt) { this.processedAt = processedAt; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}