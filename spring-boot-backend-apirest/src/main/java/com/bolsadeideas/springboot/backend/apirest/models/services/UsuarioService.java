package com.bolsadeideas.springboot.backend.apirest.models.services;

import com.bolsadeideas.springboot.backend.apirest.models.dao.IUserDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
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

import java.util.List;
import java.util.stream.Collectors;

@Service
public class UsuarioService implements IUserService, UserDetailsService {

    private Logger logger = LoggerFactory.getLogger(UsuarioService.class);

    @Autowired
    private IUserDao userDao;

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
}
