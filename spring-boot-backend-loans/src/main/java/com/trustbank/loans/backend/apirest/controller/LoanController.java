package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.dto.LoanRequest;
import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.service.LoanService;
import com.trustbank.loans.backend.apirest.service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/loans")
@CrossOrigin(origins = "*")
public class LoanController {
    
    @Autowired
    private LoanService loanService;
    
    @Autowired
    private UserService userService;
    
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
    
    @GetMapping("/total-remaining")
    public ResponseEntity<Double> getTotalRemainingAmount() {
        Double total = loanService.getTotalRemainingAmount();
        return ResponseEntity.ok(total != null ? total : 0.0);
    }
    
    @PostMapping("/recalculate-balances")
    public ResponseEntity<Map<String, Object>> recalculateAllBalances() {
        Map<String, Object> result = loanService.recalculateAllBalances();
        return ResponseEntity.ok(result);
    }
    

    @PostMapping
    public Loan createLoan(@RequestBody LoanRequest loanRequest) {
        User user = userService.findById(loanRequest.getUser().getId())
                .orElseThrow(() -> new RuntimeException("Usuario no encontrado"));
        
        Loan loan = new Loan();
        loan.setUser(user);
        loan.setAmount(loanRequest.getAmount());
        loan.setInterestRate(loanRequest.getInterestRate());
        loan.setInstallments(loanRequest.getInstallments());
        loan.setLoanType(loanRequest.getLoanType());
        loan.setPaymentFrequency(loanRequest.getPaymentFrequency());
        loan.setValorRealCuota(loanRequest.getValorRealCuota());
        loan.setSinCuotas(loanRequest.getSinCuotas() != null ? loanRequest.getSinCuotas() : false);
        
        // Si se proporciona fecha de inicio, usarla; si no, usar fecha actual
        if (loanRequest.getStartDate() != null) {
            loan.setStartDate(loanRequest.getStartDate());
        } else {
            loan.setStartDate(LocalDateTime.now());
        }
        
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
    
    @PutMapping("/{id}/mark-overdue")
    public ResponseEntity<Loan> markLoanAsOverdue(@PathVariable Long id) {
        try {
            Loan updatedLoan = loanService.updateStatus(id, LoanStatus.OVERDUE);
            return ResponseEntity.ok(updatedLoan);
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
    
    @PutMapping("/{id}/installments")
    public ResponseEntity<Loan> updatePaidInstallments(
            @PathVariable Long id,
            @RequestParam Integer paidInstallments) {
        try {
            Loan updatedLoan = loanService.updatePaidInstallments(id, paidInstallments);
            return ResponseEntity.ok(updatedLoan);
        } catch (RuntimeException e) {
            return ResponseEntity.notFound().build();
        }
    }
}