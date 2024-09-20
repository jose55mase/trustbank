package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ITransactionService;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping(value = "", produces = MediaType.APPLICATION_JSON_VALUE)

public class Index {

    @GetMapping()
    public String welcome(){
        return "App we running ....";
    }
}
