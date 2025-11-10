package com.bolsadeideas.springboot.backend.apirest.models.entity;

import javax.persistence.*;
import java.io.Serializable;
import java.util.Date;

@Entity
@Table(name = "documents")
public class DocumentEntity implements Serializable {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id")
    private Long userId;

    @Column(name = "document_type")
    private String documentType; // ID, PROOF_OF_ADDRESS, INCOME_PROOF, BANK_STATEMENT

    @Column(name = "file_name")
    private String fileName;

    @Column(name = "file_path")
    private String filePath;

    @Column(name = "status")
    private String status; // PENDING, APPROVED, REJECTED

    @Column(name = "uploaded_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date uploadedAt;

    @Column(name = "processed_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date processedAt;

    @Column(name = "admin_notes")
    private String adminNotes;

    private static final long serialVersionUID = 1L;

    public DocumentEntity() {
        this.uploadedAt = new Date();
        this.status = "PENDING";
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Long getUserId() { return userId; }
    public void setUserId(Long userId) { this.userId = userId; }

    public String getDocumentType() { return documentType; }
    public void setDocumentType(String documentType) { this.documentType = documentType; }

    public String getFileName() { return fileName; }
    public void setFileName(String fileName) { this.fileName = fileName; }

    public String getFilePath() { return filePath; }
    public void setFilePath(String filePath) { this.filePath = filePath; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public Date getUploadedAt() { return uploadedAt; }
    public void setUploadedAt(Date uploadedAt) { this.uploadedAt = uploadedAt; }

    public Date getProcessedAt() { return processedAt; }
    public void setProcessedAt(Date processedAt) { this.processedAt = processedAt; }

    public String getAdminNotes() { return adminNotes; }
    public void setAdminNotes(String adminNotes) { this.adminNotes = adminNotes; }
}