package com.bolsadeideas.springboot.backend.apirest.models.services;


import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IRolService;
import org.springframework.beans.factory.annotation.Autowired;

public class RolServiceImpl implements IRolService {

    @Autowired private IRolService iRolService;

    @Override
    public void sava(RolEntity rolEntity) {
        this.iRolService.sava(rolEntity);
    }
}
