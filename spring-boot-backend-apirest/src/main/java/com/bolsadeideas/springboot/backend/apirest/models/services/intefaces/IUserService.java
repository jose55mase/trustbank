package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;

import java.util.List;

public interface IUserService {
    public UserEntity findByemail(String email);
    public UserEntity findByid(Long id);
    public UserEntity save(UserEntity cliente);
    public List<UserEntity> findAll();
    public List<UserEntity> findByAdministratorManager(Integer administratorManager);
}
