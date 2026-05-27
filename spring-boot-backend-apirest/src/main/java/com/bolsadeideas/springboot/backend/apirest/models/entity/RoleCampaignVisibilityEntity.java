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
import javax.persistence.UniqueConstraint;

@Entity
@Table(name = "role_campaign_visibility",
       uniqueConstraints = @UniqueConstraint(columnNames = {"role_id", "campaign_id"}))
public class RoleCampaignVisibilityEntity implements Serializable {

    private static final long serialVersionUID = 1L;

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "role_id", nullable = false)
    private RolEntity role;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "campaign_id", nullable = false)
    private AssignmentTypeEntity campaign;

    @Column(name = "created_at")
    @Temporal(TemporalType.TIMESTAMP)
    private Date createdAt;

    public RoleCampaignVisibilityEntity() {
    }

    @PrePersist
    public void prePersist() {
        this.createdAt = new Date();
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public RolEntity getRole() {
        return role;
    }

    public void setRole(RolEntity role) {
        this.role = role;
    }

    public AssignmentTypeEntity getCampaign() {
        return campaign;
    }

    public void setCampaign(AssignmentTypeEntity campaign) {
        this.campaign = campaign;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    @Override
    public String toString() {
        return "RoleCampaignVisibilityEntity{" +
                "id=" + id +
                ", role=" + (role != null ? role.getId() : null) +
                ", campaign=" + (campaign != null ? campaign.getId() : null) +
                '}';
    }
}
