package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.Permission;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface PermissionRepository extends JpaRepository<Permission, Long> {
    Optional<Permission> findByModuleKey(String moduleKey);
}