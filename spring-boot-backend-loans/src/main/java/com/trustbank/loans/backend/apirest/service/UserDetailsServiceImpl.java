package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.AuthUser;
import com.trustbank.loans.backend.apirest.repository.AuthUserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import java.util.ArrayList;

@Service
public class UserDetailsServiceImpl implements UserDetailsService {
    
    @Autowired
    private AuthUserRepository authUserRepository;
    
    @Override
    public UserDetails loadUserByUsername(String username) throws UsernameNotFoundException {
        AuthUser authUser = authUserRepository.findByUsername(username)
                .orElseThrow(() -> new UsernameNotFoundException("Usuario no encontrado: " + username));
        
        return User.builder()
                .username(authUser.getUsername())
                .password(authUser.getPassword())
                .disabled(!authUser.getEnabled())
                .authorities(new ArrayList<>())
                .build();
    }
}