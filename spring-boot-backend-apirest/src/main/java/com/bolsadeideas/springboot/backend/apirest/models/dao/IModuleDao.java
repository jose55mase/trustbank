package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface IModuleDao extends JpaRepository<ModuleEntity, Long> {

    public ModuleEntity findByCode(String code);

    public List<ModuleEntity> findAllByOrderByDisplayOrderAsc();
}
