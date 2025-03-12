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

@CrossOrigin(origins = { "https://guardianstrustbank.com" })
//@CrossOrigin(origins = { "http://localhost:4200" })
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

        UserEntity user = this.usuarioService.findByemail(userEntity.getEmail());

        if(user == null){
            user = this.usuarioService.save(userEntity);
            return new RestResponse(HttpStatus.OK.value(),
                    "Operacion correcta",user);
        }else {
            return new RestResponse(HttpStatus.NON_AUTHORITATIVE_INFORMATION.value(),
                    "Operacion incorrecta",user);
        }
    }


}
