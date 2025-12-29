package com.trustbank.loans.backend.apirest.repository;

import com.trustbank.loans.backend.apirest.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface UserRepository extends JpaRepository<User, Long> {
    boolean existsByUserCode(String userCode);
    User findByUserCode(String userCode);
    List<User> findAllByOrderByRegistrationDateDesc();
}