package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.dto.UserRequest;
import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;

@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*")
public class UserController {
    
    @Autowired
    private UserService userService;
    
    @GetMapping
    public List<User> getAllUsers() {
        return userService.findAll();
    }
    
    @GetMapping("/search-by-code")
    public List<User> getUsersByCodeAlphabetical(@RequestParam String code) {
        return userService.findByUserCodeOrderedAlphabetically(code);
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<User> getUserById(@PathVariable Long id) {
        return userService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @PostMapping
    public User createUser(@RequestBody UserRequest userRequest) {
        User user = new User();
        user.setName(userRequest.getName());
        user.setUserCode(userRequest.getUserCode());
        user.setPhone(userRequest.getPhone());
        user.setDireccion(userRequest.getDireccion());
        user.setReferenceName(userRequest.getReferenceName());
        user.setReferencePhone(userRequest.getReferencePhone());
        
        // Si se proporciona fecha de registro, usarla; si no, usar fecha actual
        if (userRequest.getRegistrationDate() != null) {
            user.setRegistrationDate(userRequest.getRegistrationDate());
        } else {
            user.setRegistrationDate(LocalDateTime.now());
        }
        
        return userService.save(user);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<User> updateUser(@PathVariable Long id, @RequestBody User user) {
        return userService.findById(id)
                .map(existingUser -> {
                    user.setId(id);
                    return ResponseEntity.ok(userService.save(user));
                })
                .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteUser(@PathVariable Long id) {
        if (userService.findById(id).isPresent()) {
            userService.deleteById(id);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
}