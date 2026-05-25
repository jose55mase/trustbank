package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.dao.RolDao;
import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUploadFileService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.core.io.Resource;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.net.MalformedURLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/user")
public class UserConstructor {

    private static final Logger logger = LoggerFactory.getLogger(UserConstructor.class);
    private static final String DEFAULT_ROLE_NAME = "ROLE_USER";

    @Autowired UsuarioService usuarioService;
    @Autowired private IUploadFileService uploadService;
    @Autowired private BCryptPasswordEncoder passwordEncoder;
    @Autowired private RolDao rolDao;



    @GetMapping("/getUserByEmail/{email}")
    public UserEntity getUserByEmail(@PathVariable String email) {
        return this.usuarioService.findByemail(email);
    }

    @PostMapping("/upload")
    public ResponseEntity<?> upload(@RequestParam("archivo") MultipartFile archivo, @RequestParam("id") Long id){
        Map<String, Object> response = new HashMap<>();
        UserEntity cliente = usuarioService.findByid(id);
        if(!archivo.isEmpty()) {
            String nombreArchivo = null;
            try {
                nombreArchivo = uploadService.copiar(archivo);
            } catch (IOException e) {
                response.put("mensaje", "Error al subir la imagen del cliente");
                String errorMessage = e.getMessage() != null ? e.getMessage() : "Error desconocido";
                if (e.getCause() != null && e.getCause().getMessage() != null) {
                    errorMessage = errorMessage.concat(": ").concat(e.getCause().getMessage());
                }
                response.put("error", errorMessage);
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getFoto();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setFoto(nombreArchivo);
            cliente.setFotoStatus("PENDING");

            usuarioService.save(cliente);
            response.put("cliente", cliente);
            response.put("mensaje", "Has subido correctamente la imagen: " + nombreArchivo);
        }
        return new ResponseEntity<Map<String, Object>>(response, HttpStatus.CREATED);
    }

    @PostMapping("/upload/documentFrom")
    public ResponseEntity<?> uploadDocumentFrom(@RequestParam("archivo") MultipartFile archivo, @RequestParam("id") Long id){
        Map<String, Object> response = new HashMap<>();
        UserEntity cliente = usuarioService.findByid(id);
        if(!archivo.isEmpty()) {
            String nombreArchivo = null;
            try {
                nombreArchivo = uploadService.copiar(archivo);
            } catch (IOException e) {
                response.put("mensaje", "Error al subir la imagen del cliente");
                String errorMessage = e.getMessage() != null ? e.getMessage() : "Error desconocido";
                if (e.getCause() != null && e.getCause().getMessage() != null) {
                    errorMessage = errorMessage.concat(": ").concat(e.getCause().getMessage());
                }
                response.put("error", errorMessage);
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getDocumentFrom();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setDocumentFrom(nombreArchivo);
            cliente.setDocumentFromStatus("PENDING");
            usuarioService.save(cliente);
            response.put("cliente", cliente);
            response.put("mensaje", "Has subido correctamente la imagen: " + nombreArchivo);
        }
        return new ResponseEntity<Map<String, Object>>(response, HttpStatus.CREATED);
    }

    @PostMapping("/upload/documentBack")
    public ResponseEntity<?> uploadDocumentBack(@RequestParam("archivo") MultipartFile archivo, @RequestParam("id") Long id){
        Map<String, Object> response = new HashMap<>();
        UserEntity cliente = usuarioService.findByid(id);
        if(!archivo.isEmpty()) {
            String nombreArchivo = null;
            try {
                nombreArchivo = uploadService.copiar(archivo);
            } catch (IOException e) {
                response.put("mensaje", "Error al subir la imagen del cliente");
                String errorMessage = e.getMessage() != null ? e.getMessage() : "Error desconocido";
                if (e.getCause() != null && e.getCause().getMessage() != null) {
                    errorMessage = errorMessage.concat(": ").concat(e.getCause().getMessage());
                }
                response.put("error", errorMessage);
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getDocumentBack();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setDocumentBack(nombreArchivo);
            cliente.setDocumentBackStatus("PENDING");
            usuarioService.save(cliente);
            response.put("cliente", cliente);
            response.put("mensaje", "Has subido correctamente la imagen: " + nombreArchivo);
        }
        return new ResponseEntity<Map<String, Object>>(response, HttpStatus.CREATED);
    }

    @GetMapping("/uploads/img/{nombreFoto:.+}")
    public ResponseEntity<Resource> verFoto(@PathVariable String nombreFoto){
        Resource recurso = null;

        try {
            recurso = uploadService.cargar(nombreFoto);
        } catch (MalformedURLException e) {
            e.printStackTrace();
        }

        HttpHeaders cabecera = new HttpHeaders();
        cabecera.add(HttpHeaders.CONTENT_DISPOSITION, "attachment; filename=\"" + recurso.getFilename() + "\"");

        return new ResponseEntity<Resource>(recurso, cabecera, HttpStatus.OK);
    }

    @PutMapping("/update")
    public UserEntity update(@RequestBody UserEntity userEntity){
        UserEntity cliente = usuarioService.findByemail(userEntity.getEmail());


        cliente.setMoneyclean(userEntity.getMoneyclean());
        cliente.setAboutme(userEntity.getAboutme());
        cliente.setCity(userEntity.getCity());
        cliente.setCountry(userEntity.getCountry());
        cliente.setFistName(userEntity.getFistName());
        cliente.setLastName(userEntity.getLastName());
        cliente.setEmail(userEntity.getEmail());
        cliente.setPostal(userEntity.getPostal());
        cliente.setDocumentsAprov(userEntity.getDocumentsAprov());
        return this.usuarioService.save(cliente);
    }

    @GetMapping("/findAll")
    public  List<UserEntity> findAll(){
        return this.usuarioService.findAll();
    }

    @GetMapping("/findByAdministratorManager/{administratorManager}")
    public  RestResponse findByAdministratorManager(@PathVariable Integer administratorManager){
        return new RestResponse(HttpStatus.NON_AUTHORITATIVE_INFORMATION.value(),
                "Operacion incorrecta", this.usuarioService.findByAdministratorManager(administratorManager));
    }

    @PostMapping("/save")
    public RestResponse save(@RequestBody UserEntity userEntity){
        userEntity.setDocumentsAprov("{\"foto\":false,\"fromt\":false,\"back\":false}");
        userEntity.setPassword(this.passwordEncoder.encode(userEntity.getPassword()));
        
        // Establecer valores por defecto
        if (userEntity.getStatus() == null) {
            userEntity.setStatus(true);
        }
        if (userEntity.getAccountStatus() == null) {
            userEntity.setAccountStatus("ACTIVE");
        }
        
        // Inicializar saldo en 0 si no se especifica
        if (userEntity.getMoneyclean() == null) {
            userEntity.setMoneyclean(0);
        }

        // Validar email único
        UserEntity existingUserByEmail = this.usuarioService.findByemail(userEntity.getEmail());
        if(existingUserByEmail != null){
            return new RestResponse(HttpStatus.CONFLICT.value(),
                    "El email ya está registrado", null);
        }
        
        // Validar username único
        UserEntity existingUserByUsername = this.usuarioService.findByUsername(userEntity.getUsername());
        if(existingUserByUsername != null){
            return new RestResponse(HttpStatus.CONFLICT.value(),
                    "El nombre de usuario ya está en uso", null);
        }

        // Asignar rol por defecto (ROLE_USER) desde la base de datos
        Optional<RolEntity> defaultRole = rolDao.findByName(DEFAULT_ROLE_NAME);
        if (defaultRole.isPresent()) {
            List<RolEntity> roles = new ArrayList<>();
            roles.add(defaultRole.get());
            userEntity.setRols(roles);
        } else {
            logger.warn("Default role '{}' not found in database. User will be created without a role.", DEFAULT_ROLE_NAME);
        }

        UserEntity user = this.usuarioService.save(userEntity);
        return new RestResponse(HttpStatus.OK.value(),
                "Usuario registrado exitosamente", user);
    }
    
    // Nuevos endpoints para gestión de usuarios

    @GetMapping("/all")
    public ResponseEntity<List<UserEntity>> getAllUsers() {
        try {
            List<UserEntity> users = this.usuarioService.findAllOrderByCreatedAtDesc();
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Sesión cerrada exitosamente");
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
    

    @GetMapping("/{id}")
    public ResponseEntity<UserEntity> getUserById(@PathVariable Long id) {
        try {
            UserEntity user = this.usuarioService.findByid(id);
            if (user != null) {
                return new ResponseEntity<>(user, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @GetMapping("/byStatus/{status}")
    public ResponseEntity<List<UserEntity>> getUsersByStatus(@PathVariable String status) {
        try {
            List<UserEntity> users = this.usuarioService.findByAccountStatus(status);
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @GetMapping("/search")
    public ResponseEntity<List<UserEntity>> searchUsers(@RequestParam String q) {
        try {
            List<UserEntity> users = this.usuarioService.searchUsers(q);
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @GetMapping("/stats")
    public ResponseEntity<Map<String, Long>> getUserStats() {
        try {
            Map<String, Long> stats = this.usuarioService.getUserStats();
            return new ResponseEntity<>(stats, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @PutMapping("/updateStatus/{id}")
    public ResponseEntity<UserEntity> updateUserStatus(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String status = request.get("accountStatus");
            UserEntity updatedUser = this.usuarioService.updateUserStatus(id, status);
            if (updatedUser != null) {
                return new ResponseEntity<>(updatedUser, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @PutMapping("/updateRole/{id}")
    public ResponseEntity<UserEntity> updateUserRole(@PathVariable Long id, @RequestBody Map<String, String> request) {
        try {
            String roleName = request.get("role");
            UserEntity updatedUser = this.usuarioService.updateUserRole(id, roleName);
            if (updatedUser != null) {
                return new ResponseEntity<>(updatedUser, HttpStatus.OK);
            } else {
                return new ResponseEntity<>(HttpStatus.NOT_FOUND);
            }
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @GetMapping("/roles")
    public ResponseEntity<List<RolEntity>> getAllRoles() {
        try {
            List<RolEntity> roles = this.usuarioService.getAllRoles();
            return new ResponseEntity<>(roles, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    

    @PutMapping("/changePassword")
    public ResponseEntity<Map<String, Object>> changePassword(@RequestBody Map<String, String> request) {
        Map<String, Object> response = new HashMap<>();
        try {
            String email = request.get("email");
            String currentPassword = request.get("currentPassword");
            String newPassword = request.get("newPassword");
            
            UserEntity user = this.usuarioService.findByemail(email);
            if (user == null) {
                response.put("success", false);
                response.put("message", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }
            
            // Verificar contraseña actual
            if (!passwordEncoder.matches(currentPassword, user.getPassword())) {
                response.put("success", false);
                response.put("message", "Contraseña actual incorrecta");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }
            
            // Actualizar contraseña
            user.setPassword(passwordEncoder.encode(newPassword));
            this.usuarioService.save(user);
            
            response.put("success", true);
            response.put("message", "Contraseña actualizada exitosamente");
            return new ResponseEntity<>(response, HttpStatus.OK);
            
        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error interno del servidor");
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

    @PutMapping("/adjustBalance/{id}")
    public ResponseEntity<Map<String, Object>> adjustBalance(
            @PathVariable Long id,
            @RequestBody Map<String, Object> request) {
        Map<String, Object> response = new HashMap<>();
        try {
            Double amount = Double.valueOf(request.get("amount").toString());
            String operation = request.get("operation").toString(); // ADD or SUBTRACT
            String reason = request.get("reason") != null ? request.get("reason").toString() : "Ajuste administrativo";

            UserEntity user = this.usuarioService.findByid(id);
            if (user == null) {
                response.put("success", false);
                response.put("message", "Usuario no encontrado");
                return new ResponseEntity<>(response, HttpStatus.NOT_FOUND);
            }

            Integer currentBalance = user.getMoneyclean() != null ? user.getMoneyclean() : 0;
            Integer newBalance;

            if ("ADD".equalsIgnoreCase(operation)) {
                newBalance = currentBalance + amount.intValue();
            } else if ("SUBTRACT".equalsIgnoreCase(operation)) {
                if (currentBalance < amount.intValue()) {
                    response.put("success", false);
                    response.put("message", "Saldo insuficiente. Saldo actual: $" + currentBalance);
                    return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
                }
                newBalance = currentBalance - amount.intValue();
            } else {
                response.put("success", false);
                response.put("message", "Operación inválida. Use ADD o SUBTRACT");
                return new ResponseEntity<>(response, HttpStatus.BAD_REQUEST);
            }

            user.setMoneyclean(newBalance);
            this.usuarioService.save(user);

            response.put("success", true);
            response.put("message", "Saldo actualizado exitosamente");
            response.put("previousBalance", currentBalance);
            response.put("newBalance", newBalance);
            response.put("operation", operation);
            response.put("amount", amount.intValue());
            response.put("user", user);
            return new ResponseEntity<>(response, HttpStatus.OK);

        } catch (Exception e) {
            response.put("success", false);
            response.put("message", "Error: " + e.getMessage());
            return new ResponseEntity<>(response, HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }

}
