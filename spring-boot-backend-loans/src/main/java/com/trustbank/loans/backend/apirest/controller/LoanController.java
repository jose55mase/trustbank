package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import com.trustbank.loans.backend.apirest.service.LoanService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;

@RestController
@RequestMapping("/api/loans")
@CrossOrigin(origins = "*")
public class LoanController {
    
    @Autowired
    private LoanService loanService;
    
    @GetMapping
    public List<Loan> getAllLoans() {
        List<Loan> loans = loanService.findAll();
        // Forzar la carga del usuario para cada préstamo
        loans.forEach(loan -> {
            if (loan.getUser() != null) {
                loan.getUser().getName(); // Esto fuerza la carga lazy
            }
        });
        return loans;
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Loan> getLoanById(@PathVariable Long id) {
        return loanService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/user/{userId}")
    public List<Loan> getLoansByUserId(@PathVariable Long userId) {
        return loanService.findByUserId(userId);
    }
    
    @GetMapping("/total-active")
    public ResponseEntity<Double> getTotalActiveLoanAmount() {
        Double total = loanService.getTotalActiveLoanAmount();
        return ResponseEntity.ok(total != null ? total : 0.0);
    }
    
    @PostMapping
    public Loan createLoan(@RequestBody Loan loan) {
        return loanService.save(loan);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Loan> updateLoan(@PathVariable Long id, @RequestBody Loan loan) {
        return loanService.findById(id)
                .map(existingLoan -> {
                    loan.setId(id);
                    return ResponseEntity.ok(loanService.save(loan));
                })
                .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteLoan(@PathVariable Long id) {
        if (loanService.findById(id).isPresent()) {
            loanService.deleteById(id);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
    
    @PutMapping("/{id}/status")
    public ResponseEntity<Loan> updateLoanStatus(@PathVariable Long id, @RequestParam String status) {
        try {
            LoanStatus loanStatus = LoanStatus.valueOf(status.toUpperCase());
            Loan updatedLoan = loanService.updateStatus(id, loanStatus);
            return ResponseEntity.ok(updatedLoan);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().build();
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
    
    @PutMapping("/{id}/payment-status")
    public ResponseEntity<Loan> updatePaymentStatus(
            @PathVariable Long id,
            @RequestParam(required = false) Boolean pagoAnterior,
            @RequestParam(required = false) Boolean pagoActual) {
        try {
            Loan updatedLoan = loanService.updatePaymentStatus(id, pagoAnterior, pagoActual);
            return ResponseEntity.ok(updatedLoan);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}