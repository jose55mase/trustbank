package com.bolsadeideas.springboot.backend.apirest.controllers;

import com.bolsadeideas.springboot.backend.apirest.models.entity.CreditEntity;
import com.bolsadeideas.springboot.backend.apirest.models.dao.ICreditDao;
import com.bolsadeideas.springboot.backend.apirest.utils.RestResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.web.bind.annotation.*;

import java.util.Date;
import java.util.List;

@CrossOrigin(origins = {"http://localhost:4200", "http://localhost:8080"})
@RestController
@RequestMapping("/api/credits")
public class CreditController {

    @Autowired
    private ICreditDao creditDao;

    @PostMapping("/simulate")
    public RestResponse simulateCredit(@RequestBody CreditEntity credit) {
        // Calcular pago mensual
        double monthlyRate = credit.getInterestRate() / 100 / 12;
        int months = credit.getTermMonths();
        double amount = credit.getAmount();
        
        double monthlyPayment = (amount * monthlyRate * Math.pow(1 + monthlyRate, months)) / 
                               (Math.pow(1 + monthlyRate, months) - 1);
        
        credit.setMonthlyPayment(monthlyPayment);
        return new RestResponse(HttpStatus.OK.value(), "Simulación de crédito", credit);
    }

    @PostMapping("/apply")
    public RestResponse applyForCredit(@RequestBody CreditEntity credit) {
        CreditEntity saved = creditDao.save(credit);
        return new RestResponse(HttpStatus.CREATED.value(), "Solicitud de crédito enviada", saved);
    }

    @GetMapping("/user/{userId}")
    public RestResponse getUserCredits(@PathVariable Long userId) {
        List<CreditEntity> credits = creditDao.findByUserId(userId);
        return new RestResponse(HttpStatus.OK.value(), "Créditos del usuario", credits);
    }

    @GetMapping("/pending")
    public RestResponse getPendingCredits() {
        List<CreditEntity> credits = creditDao.findByStatus("PENDING");
        return new RestResponse(HttpStatus.OK.value(), "Créditos pendientes", credits);
    }

    @PutMapping("/approve/{id}")
    public RestResponse approveCredit(@PathVariable Long id) {
        CreditEntity credit = creditDao.findById(id).orElse(null);
        if (credit != null) {
            credit.setStatus("APPROVED");
            credit.setApprovedAt(new Date());
            creditDao.save(credit);
            return new RestResponse(HttpStatus.OK.value(), "Crédito aprobado", credit);
        }
        return new RestResponse(HttpStatus.NOT_FOUND.value(), "Crédito no encontrado", null);
    }
}