package com.bolsadeideas.springboot.backend.apirest.models.services.intefaces;

import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;

import java.util.List;
import java.util.Map;

public interface IUserService {
    public UserEntity findByemail(String email);
    public UserEntity findByUsername(String username);
    public UserEntity findByid(Long id);
    public UserEntity save(UserEntity cliente);
    public List<UserEntity> findAll();
    public List<UserEntity> findByAdministratorManager(Integer administratorManager);
    
    // Nuevos métodos para gestión de usuarios
    public List<UserEntity> findAllOrderByCreatedAtDesc();
    public List<UserEntity> findByAccountStatus(String accountStatus);
    public List<UserEntity> searchUsers(String query);
    public Map<String, Long> getUserStats();
    public UserEntity updateUserStatus(Long userId, String status);
    public List<UserEntity> findUsersWithDocuments();
    public UserEntity findById(Long id);
}
