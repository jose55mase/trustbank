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
import java.util.HashMap;
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
    
    @GetMapping("/user/{userId}/notes")
    public ResponseEntity<Map<String, String>> getLoanNotesByUserId(@PathVariable Long userId) {
        List<Loan> loans = loanService.findByUserId(userId);
        Map<String, String> notes = new HashMap<>();
        
        for (Loan loan : loans) {
            // Obtener solo la transacción más reciente con nota
            if (loan.getTransactions() != null && !loan.getTransactions().isEmpty()) {
                loan.getTransactions().stream()
                    .filter(t -> t.getMontoRestanteCompletarCuota() != null && 
                               !t.getMontoRestanteCompletarCuota().trim().isEmpty())
                    .max((t1, t2) -> t1.getDate().compareTo(t2.getDate()))
                    .ifPresent(t -> notes.put(loan.getId().toString(), t.getMontoRestanteCompletarCuota()));
            }
        }
        
        return ResponseEntity.ok(notes);
    }
    
    @GetMapping("/user/{userId}/active-and-overdue")
    public List<Loan> getActiveAndOverdueLoansByUserId(@PathVariable Long userId) {
        List<Loan> loans = loanService.findActiveAndOverdueLoansByUserId(userId);
        loans.forEach(loan -> {
            if (loan.getUser() != null) {
                loan.getUser().getName();
            }
        });
        return loans;
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
    
    @GetMapping("/active")
    public List<Loan> getActiveLoans() {
        List<Loan> loans = loanService.findByStatus(LoanStatus.ACTIVE);
        loans.forEach(loan -> {
            if (loan.getUser() != null) {
                loan.getUser().getName();
            }
        });
        return loans;
    }
    
    @GetMapping("/active-and-overdue")
    public List<Loan> getActiveAndOverdueLoans() {
        List<Loan> loans = loanService.findActiveAndOverdueLoans();
        loans.forEach(loan -> {
            if (loan.getUser() != null) {
                loan.getUser().getName();
            }
        });
        return loans;
    }
    
    @GetMapping("/home-stats")
    public ResponseEntity<Map<String, Object>> getHomeStats() {
        Map<String, Object> stats = new HashMap<>();
        
        List<Loan> activeLoans = loanService.findByStatus(LoanStatus.ACTIVE);
        List<Loan> overdueLoans = loanService.findByStatus(LoanStatus.OVERDUE);
        
        stats.put("activeLoansCount", activeLoans.size());
        stats.put("overdueLoansCount", overdueLoans.size());
        stats.put("activeLoans", activeLoans);
        
        // Solo incluir préstamos vencidos si existen
        if (!overdueLoans.isEmpty()) {
            stats.put("overdueLoans", overdueLoans);
        }
        
        return ResponseEntity.ok(stats);
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
    
    @GetMapping("/{id}/progress")
    public ResponseEntity<Map<String, Object>> getLoanProgress(@PathVariable Long id) {
        return loanService.findById(id)
                .map(loan -> {
                    Map<String, Object> progress = new java.util.HashMap<>();
                    progress.put("loanId", loan.getId());
                    progress.put("totalInstallments", loan.getInstallments());
                    progress.put("paidInstallments", loan.getPaidInstallments());
                    progress.put("remainingInstallments", loan.getInstallments() - loan.getPaidInstallments());
                    progress.put("originalAmount", loan.getAmount());
                    progress.put("remainingAmount", loan.getRemainingAmount());
                    progress.put("status", loan.getStatus());
                    
                    // Calcular progreso como porcentaje
                    double progressPercentage = loan.getInstallments() > 0 ? 
                        (double) loan.getPaidInstallments() / loan.getInstallments() * 100 : 0;
                    progress.put("progressPercentage", Math.round(progressPercentage * 100.0) / 100.0);
                    
                    // Contar transacciones reales
                    int actualPaymentCount = 0;
                    if (loan.getTransactions() != null) {
                        actualPaymentCount = (int) loan.getTransactions().stream()
                            .filter(t -> t.getPrincipalAmount() != null && 
                                   t.getPrincipalAmount().compareTo(java.math.BigDecimal.ZERO) > 0)
                            .count();
                    }
                    progress.put("actualPaymentCount", actualPaymentCount);
                    
                    return ResponseEntity.ok(progress);
                })
                .orElse(ResponseEntity.notFound().build());
    }
}