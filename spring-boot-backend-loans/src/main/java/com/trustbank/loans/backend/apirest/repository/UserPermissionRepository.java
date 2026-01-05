package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.UserPermission;
import com.trustbank.loans.backend.apirest.entity.AuthUser;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserPermissionRepository extends JpaRepository<UserPermission, Long> {
    List<UserPermission> findByAuthUser(AuthUser authUser);
    List<UserPermission> findByAuthUserAndGranted(AuthUser authUser, Boolean granted);
    
    @Modifying
    @Query("DELETE FROM UserPermission up WHERE up.authUser = :authUser")
    void deleteByAuthUser(@Param("authUser") AuthUser authUser);
}