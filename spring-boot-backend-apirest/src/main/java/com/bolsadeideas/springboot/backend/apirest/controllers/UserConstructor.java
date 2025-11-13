package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.RolEntity;
import com.bolsadeideas.springboot.backend.apirest.models.entity.UserEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.UsuarioService;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.IUploadFileService;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
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

@RestController
@RequestMapping("/api/user")
public class UserConstructor {

    @Autowired UsuarioService usuarioService;
    @Autowired private IUploadFileService uploadService;
    @Autowired private BCryptPasswordEncoder passwordEncoder;



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
                response.put("error", e.getMessage().concat(": ").concat(e.getCause().getMessage()));
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getFoto();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setFoto(nombreArchivo);



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
                response.put("error", e.getMessage().concat(": ").concat(e.getCause().getMessage()));
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getDocumentFrom();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setDocumentFrom(nombreArchivo);
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
                response.put("error", e.getMessage().concat(": ").concat(e.getCause().getMessage()));
                return new ResponseEntity<Map<String, Object>>(response, HttpStatus.INTERNAL_SERVER_ERROR);
            }
            String nombreFotoAnterior = cliente.getDocumentBack();
            uploadService.eliminar(nombreFotoAnterior);
            cliente.setDocumentBack(nombreArchivo);
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
        
        // Asignar rol USER por defecto - obtener desde base de datos
        // Comentamos la asignación de roles por ahora para evitar el error
        // Los roles se pueden asignar después o mediante otro endpoint
        
        // Establecer valores por defecto
        if (userEntity.getStatus() == null) {
            userEntity.setStatus(true);
        }
        if (userEntity.getAccountStatus() == null) {
            userEntity.setAccountStatus("ACTIVE");
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

        UserEntity user = this.usuarioService.save(userEntity);
        return new RestResponse(HttpStatus.OK.value(),
                "Usuario registrado exitosamente", user);
    }
    
    // Nuevos endpoints para gestión de usuarios
    @CrossOrigin(origins = "*")
    @GetMapping("/all")
    public ResponseEntity<List<UserEntity>> getAllUsers() {
        try {
            List<UserEntity> users = this.usuarioService.findAllOrderByCreatedAtDesc();
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @CrossOrigin(origins = "*")
    @PostMapping("/logout")
    public ResponseEntity<?> logout() {
        Map<String, Object> response = new HashMap<>();
        response.put("success", true);
        response.put("message", "Sesión cerrada exitosamente");
        return new ResponseEntity<>(response, HttpStatus.OK);
    }
    
    @CrossOrigin(origins = "*")
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
    
    @CrossOrigin(origins = "*")
    @GetMapping("/byStatus/{status}")
    public ResponseEntity<List<UserEntity>> getUsersByStatus(@PathVariable String status) {
        try {
            List<UserEntity> users = this.usuarioService.findByAccountStatus(status);
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @CrossOrigin(origins = "*")
    @GetMapping("/search")
    public ResponseEntity<List<UserEntity>> searchUsers(@RequestParam String q) {
        try {
            List<UserEntity> users = this.usuarioService.searchUsers(q);
            return new ResponseEntity<>(users, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @CrossOrigin(origins = "*")
    @GetMapping("/stats")
    public ResponseEntity<Map<String, Long>> getUserStats() {
        try {
            Map<String, Long> stats = this.usuarioService.getUserStats();
            return new ResponseEntity<>(stats, HttpStatus.OK);
        } catch (Exception e) {
            return new ResponseEntity<>(HttpStatus.INTERNAL_SERVER_ERROR);
        }
    }
    
    @CrossOrigin(origins = "*")
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

}
