package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;

import java.util.List;

public interface IModuleService {

    List<ModuleEntity> findAll();

    ModuleEntity findById(Long id);

    ModuleEntity findByCode(String code);
}
