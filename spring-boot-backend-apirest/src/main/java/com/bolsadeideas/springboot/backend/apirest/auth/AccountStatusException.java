package com.bolsadeideas.springboot.backend.apirest.auth;

import org.springframework.security.core.userdetails.UsernameNotFoundException;

public class AccountStatusException extends UsernameNotFoundException {
    
    private String statusType;
    
    public AccountStatusException(String msg, String statusType) {
        super(msg);
        this.statusType = statusType;
    }
    
    public String getStatusType() {
        return statusType;
    }
}