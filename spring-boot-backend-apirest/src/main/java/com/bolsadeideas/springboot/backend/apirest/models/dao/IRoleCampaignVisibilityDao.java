package com.bolsadeideas.springboot.backend.apirest.models.dao;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.transaction.annotation.Transactional;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RoleCampaignVisibilityEntity;

public interface IRoleCampaignVisibilityDao extends JpaRepository<RoleCampaignVisibilityEntity, Long> {

    List<RoleCampaignVisibilityEntity> findByRoleId(Long roleId);

    void deleteByRoleId(Long roleId);
}
