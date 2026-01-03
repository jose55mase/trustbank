package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.service.OverdueLoanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/loans")
@CrossOrigin(origins = "*")
public class OverdueLoanController {

    @Autowired
    private OverdueLoanService overdueLoanService;

    @PostMapping("/check-overdue")
    public ResponseEntity<Map<String, Object>> checkOverdueLoans() {
        List<Loan> overdueLoans = overdueLoanService.checkOverdueLoans();
        
        return ResponseEntity.ok(Map.of(
            "message", "Verificación de préstamos vencidos completada",
            "overdueCount", overdueLoans.size(),
            "overdueLoans", overdueLoans
        ));
    }

    @GetMapping("/overdue")
    public List<Loan> getOverdueLoans() {
        return overdueLoanService.getOverdueLoans();
    }

    @GetMapping("/overdue/count")
    public ResponseEntity<Integer> getOverdueLoansCount() {
        return ResponseEntity.ok(overdueLoanService.getOverdueLoansCount());
    }
}