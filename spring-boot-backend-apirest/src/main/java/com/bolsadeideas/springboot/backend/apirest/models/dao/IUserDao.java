package com.bolsadeideas.springboot.backend.apirest.models.dao;

import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.CrudRepository;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface IUserDao extends CrudRepository<UserEntity, Long> {
    public List<UserEntity> findByAdministratorManagerOrderByIdDesc(Integer administratorManager);
    public UserEntity findByemail(String email);
    public UserEntity findByUsername(String username);
    public UserEntity findByid(Long id);
    
    // Nuevos métodos para gestión de usuarios
    @Query("SELECT u FROM UserEntity u ORDER BY u.createdAt DESC")
    public List<UserEntity> findAllOrderByCreatedAtDesc();
    
    public List<UserEntity> findByAccountStatusOrderByCreatedAtDesc(String accountStatus);
    
    @Query("SELECT u FROM UserEntity u WHERE LOWER(u.fistName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(u.lastName) LIKE LOWER(CONCAT('%', :query, '%')) OR LOWER(u.email) LIKE LOWER(CONCAT('%', :query, '%')) ORDER BY u.createdAt DESC")
    public List<UserEntity> searchUsersOrderByCreatedAtDesc(@Param("query") String query);
    
    @Query("SELECT COUNT(u) FROM UserEntity u")
    public Long countAllUsers();
    
    @Query("SELECT COUNT(u) FROM UserEntity u WHERE u.accountStatus = :status")
    public Long countUsersByStatus(@Param("status") String status);
}
