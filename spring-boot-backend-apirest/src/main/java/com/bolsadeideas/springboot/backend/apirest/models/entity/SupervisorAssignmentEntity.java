package com.bolsadeideas.springboot.backend.apirest.models.entity;

import java.io.Serializable;
import java.util.Date;

import javax.persistence.Column;
import javax.persistence.Entity;
import javax.persistence.FetchType;
import javax.persistence.GeneratedValue;
import javax.persistence.GenerationType;
import javax.persistence.Id;
import javax.persistence.JoinColumn;
import javax.persistence.ManyToOne;
import javax.persistence.PrePersist;
import javax.persistence.Table;
import javax.persistence.Temporal;
import javax.persistence.TemporalType;

@Entity
@Table(name = "supervisor_assignments")
public class SupervisorAssignmentEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "user_id", nullable = false)
    private UserEntity user;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "assignment_type_id", nullable = false)
    private AssignmentTypeEntity assignmentType;

    @Column(name = "assigned_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date assignedAt;

    public SupervisorAssignmentEntity() {
    }

    @PrePersist
    public void prePersist() {
        this.assignedAt = new Date();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public UserEntity getUser() {
        return user;
    }

    public void setUser(UserEntity user) {
        this.user = user;
    }

    public AssignmentTypeEntity getAssignmentType() {
        return assignmentType;
    }

    public void setAssignmentType(AssignmentTypeEntity assignmentType) {
        this.assignmentType = assignmentType;
    }

    public Date getAssignedAt() {
        return assignedAt;
    }

    public void setAssignedAt(Date assignedAt) {
        this.assignedAt = assignedAt;
    }

    @Override
    public String toString() {
        return "SupervisorAssignmentEntity{" +
                "id=" + id +
                ", userId=" + (user != null ? user.getId() : null) +
                ", assignmentTypeId=" + (assignmentType != null ? assignmentType.getId() : null) +
                ", assignedAt=" + assignedAt +
                '}';
    }
}
