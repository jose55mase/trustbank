package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.dao.RolDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUserService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class UsuarioService implements IUserService, UserDetailsService {

    private Logger logger = LoggerFactory.getLogger(UsuarioService.class);

    @Autowired
    private IUserDao userDao;
    
    @Autowired
    private RolDao rolDao;

    @Override
    @Transactional(readOnly = true)
    public UserDetails loadUserByUsername(String s) throws UsernameNotFoundException {

        UserEntity userEntity = this.userDao.findByemail(s);

        if(s == null) {
            logger.error("Error en el login: no existe el usuario '"+s+"' en el sistema!");
            throw new UsernameNotFoundException("Error en el login: no existe el usuario '"+s+"' en el sistema!");
        }

        List<GrantedAuthority> authorityLis = userEntity.getRols()
                .stream()
                .map(rol -> new SimpleGrantedAuthority(rol.getName()))
                .collect(Collectors.toList());

        return new User(userEntity.getEmail(), userEntity.getPassword(), userEntity.getStatus(),true, true, true,authorityLis);
    }

    @Transactional(readOnly = true)
    @Override
    public UserEntity findByemail(String email) {
        return this.userDao.findByemail(email);
    }
    
    @Transactional(readOnly = true)
    @Override
    public UserEntity findByUsername(String username) {
        return this.userDao.findByUsername(username);
    }

    @Transactional(readOnly = true)
    @Override
    public UserEntity findByid(Long id) {
        return this.userDao.findByid(id);
    }

    @Override
    public UserEntity save(UserEntity user) {
        return userDao.save(user);
    }

    @Override
    public List<UserEntity> findAll() {
        return (List<UserEntity>) this.userDao.findAll();
    }

    @Override
    @Transactional(readOnly = true)
    public List<UserEntity> findByAdministratorManager(Integer administratorManager) {
        return this.userDao.findByAdministratorManagerOrderByIdDesc(administratorManager);
    }
    
    // Nuevos métodos para gestión de usuarios
    @Override
    @Transactional(readOnly = true)
    public List<UserEntity> findAllOrderByCreatedAtDesc() {
        return this.userDao.findAllOrderByCreatedAtDesc();
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UserEntity> findByAccountStatus(String accountStatus) {
        return this.userDao.findByAccountStatusOrderByCreatedAtDesc(accountStatus);
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UserEntity> searchUsers(String query) {
        return this.userDao.searchUsersOrderByCreatedAtDesc(query);
    }
    
    @Override
    @Transactional(readOnly = true)
    public Map<String, Long> getUserStats() {
        Map<String, Long> stats = new HashMap<>();
        stats.put("total", this.userDao.countAllUsers());
        stats.put("active", this.userDao.countUsersByStatus("ACTIVE"));
        stats.put("inactive", this.userDao.countUsersByStatus("INACTIVE"));
        stats.put("pending", this.userDao.countUsersByStatus("PENDING"));
        stats.put("suspended", this.userDao.countUsersByStatus("SUSPENDED"));
        return stats;
    }
    
    @Override
    public UserEntity updateUserStatus(Long userId, String status) {
        UserEntity user = this.userDao.findByid(userId);
        if (user != null) {
            user.setAccountStatus(status);
            return this.userDao.save(user);
        }
        return null;
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<UserEntity> findUsersWithDocuments() {
        return this.userDao.findUsersWithDocuments();
    }
    
    @Override
    @Transactional(readOnly = true)
    public UserEntity findById(Long id) {
        return this.userDao.findByid(id);
    }
    
    // Role management methods
    @Override
    public UserEntity updateUserRole(Long userId, String roleName) {
        UserEntity user = this.userDao.findByid(userId);
        if (user != null) {
            RolEntity role = findRoleByName(roleName);
            if (role != null) {
                // Clear existing roles and add new one
                user.getRols().clear();
                user.getRols().add(role);
                return this.userDao.save(user);
            }
        }
        return null;
    }
    
    @Override
    @Transactional(readOnly = true)
    public List<RolEntity> getAllRoles() {
        return (List<RolEntity>) this.rolDao.findAll();
    }
    
    @Override
    @Transactional(readOnly = true)
    public RolEntity findRoleByName(String roleName) {
        List<RolEntity> roles = getAllRoles();
        return roles.stream()
                .filter(role -> role.getName().equals(roleName))
                .findFirst()
                .orElse(null);
    }
}
