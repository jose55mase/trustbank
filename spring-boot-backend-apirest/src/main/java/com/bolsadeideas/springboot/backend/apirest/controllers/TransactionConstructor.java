package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.TransactionEntity;
import com.bolsadeideas.springboot.backend.apirest.models.services.intefaces.ITransactionService;
import org.springframework.beans.factory.annotation.Autowired;

import org.springframework.web.bind.annotation.*;

import java.util.List;


@CrossOrigin(origins = { "https://guardianstrustbank.com" })
//@CrossOrigin(origins = { "http://localhost:4200" })
@RestController
@RequestMapping("/api/transaction")
public class TransactionConstructor {

    @Autowired private ITransactionService transactionService;

    @PostMapping("/save")
    public void save(@RequestBody TransactionEntity transaction) {
        this.transactionService.save(transaction);
    }

    @GetMapping("/findByUser")
    public List<TransactionEntity> findTransactionById(@RequestParam Integer idUser){
        return this.transactionService.getTransactionByUser(idUser);
    }

    @GetMapping("/findAll/{idManageAdmin}")
    public List<TransactionEntity> findAll(@PathVariable Integer idManageAdmin){
        return this.transactionService.getAllTransaction(idManageAdmin);
    }


}
