package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import org.springframework.data.repository.CrudRepository;

import java.util.List;

public interface IUserDao extends CrudRepository<UserEntity, Long> {
    public List<UserEntity> findByAdministratorManagerOrderByIdDesc(Integer administratorManager);
    public UserEntity findByemail(String email);
    public UserEntity findByid(Long id);

}
