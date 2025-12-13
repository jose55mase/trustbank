package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.Transaction;
import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.dto.TransactionRequest;
import com.trustbank.loans.backend.apirest.service.TransactionService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.time.LocalDateTime;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;

@RestController
@RequestMapping("/api/transactions")
@CrossOrigin(origins = "*")
public class TransactionController {
    
    @Autowired
    private TransactionService transactionService;
    
    @GetMapping
    public List<Transaction> getAllTransactions() {
        return transactionService.findAll();
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Transaction> getTransactionById(@PathVariable Long id) {
        return transactionService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/loan/{loanId}")
    public List<Transaction> getTransactionsByLoanId(@PathVariable Long loanId) {
        return transactionService.findByLoanId(loanId);
    }
    
    @GetMapping("/total-payments")
    public ResponseEntity<Double> getTotalPayments() {
        Double total = transactionService.getTotalPayments();
        return ResponseEntity.ok(total != null ? total : 0.0);
    }
    
    @GetMapping("/by-date-range")
    public List<Transaction> getTransactionsByDateRange(
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate startDate,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate endDate) {
        return transactionService.findByDateRange(startDate, endDate);
    }
    
    @PostMapping
    public Transaction createTransaction(@RequestBody TransactionRequest request) {
        System.out.println("Received request: " + request.getType() + ", loan ID: " + 
            (request.getLoan() != null ? request.getLoan().getId() : "null"));
        
        Transaction transaction = new Transaction();
        transaction.setType(request.getType());
        transaction.setAmount(request.getAmount());
        transaction.setPaymentMethod(request.getPaymentMethod());
        transaction.setNotes(request.getNotes());
        transaction.setInterestAmount(request.getInterestAmount());
        transaction.setPrincipalAmount(request.getPrincipalAmount());
        transaction.setDate(LocalDateTime.now());
        
        // Set loan reference
        if (request.getLoan() != null && request.getLoan().getId() != null) {
            Loan loan = new Loan();
            loan.setId(request.getLoan().getId());
            transaction.setLoan(loan);
        }
        
        return transactionService.saveWithLoan(transaction);
    }
    
    @PutMapping("/{id}")
    public ResponseEntity<Transaction> updateTransaction(@PathVariable Long id, @RequestBody Transaction transaction) {
        return transactionService.findById(id)
                .map(existingTransaction -> {
                    transaction.setId(id);
                    return ResponseEntity.ok(transactionService.save(transaction));
                })
                .orElse(ResponseEntity.notFound().build());
    }
    
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deleteTransaction(@PathVariable Long id) {
        if (transactionService.findById(id).isPresent()) {
            transactionService.deleteById(id);
            return ResponseEntity.ok().build();
        }
        return ResponseEntity.notFound().build();
    }
}