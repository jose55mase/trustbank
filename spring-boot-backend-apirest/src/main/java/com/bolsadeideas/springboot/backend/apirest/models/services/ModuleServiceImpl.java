package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IModuleDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.ModuleEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IModuleService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class ModuleServiceImpl implements IModuleService {

    @Autowired
    private IModuleDao moduleDao;

    @Override
    @Transactional(readOnly = true)
    public List<ModuleEntity> findAll() {
        return moduleDao.findAllByOrderByDisplayOrderAsc();
    }

    @Override
    @Transactional(readOnly = true)
    public ModuleEntity findById(Long id) {
        return moduleDao.findById(id).orElseThrow(
                () -> new RuntimeException("Módulo no encontrado con ID: " + id)
        );
    }

    @Override
    @Transactional(readOnly = true)
    public ModuleEntity findByCode(String code) {
        return moduleDao.findByCode(code);
    }
}
