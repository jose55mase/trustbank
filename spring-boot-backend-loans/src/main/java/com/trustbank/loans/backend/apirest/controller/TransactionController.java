package com.trustbank.loans.backend.apirest.controller;

import com.trustbank.loans.backend.apirest.entity.Transaction;
import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.dto.TransactionRequest;
import com.trustbank.loans.backend.apirest.service.TransactionService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.time.LocalDateTime;
import java.time.LocalDate;
import org.springframework.format.annotation.DateTimeFormat;
import java.util.Map;
import java.math.BigDecimal;

@RestController
@RequestMapping("/api/transactions")
@CrossOrigin(origins = "*")
public class TransactionController {
    
    private static final Logger logger = LoggerFactory.getLogger(TransactionController.class);
    
    @Autowired
    private TransactionService transactionService;
    
    @GetMapping
    public List<Transaction> getAllTransactions() {
        logger.info("=== GET /api/transactions - Obteniendo todas las transacciones ===");
        List<Transaction> transactions = transactionService.findAll();
        logger.info("Total de transacciones encontradas: {}", transactions.size());
        
        for (Transaction t : transactions) {
            logger.info("Transacción ID: {}, Loan ID: {}, Amount: {}, Principal: {}, Interest: {}", 
                t.getId(), 
                t.getLoan() != null ? t.getLoan().getId() : "null",
                t.getAmount(),
                t.getPrincipalAmount(),
                t.getInterestAmount());
        }
        
        return transactions;
    }
    
    @GetMapping("/{id}")
    public ResponseEntity<Transaction> getTransactionById(@PathVariable Long id) {
        return transactionService.findById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
    
    @GetMapping("/loan/{loanId}")
    public List<Transaction> getTransactionsByLoanId(@PathVariable Long loanId) {
        logger.info("=== GET /api/transactions/loan/{} - Obteniendo transacciones por préstamo ===", loanId);
        List<Transaction> transactions = transactionService.findByLoanId(loanId);
        logger.info("Transacciones encontradas para préstamo {}: {}", loanId, transactions.size());
        
        BigDecimal totalPrincipal = BigDecimal.ZERO;
        for (Transaction t : transactions) {
            logger.info("  - Transacción ID: {}, Amount: {}, Principal: {}, Interest: {}, Date: {}", 
                t.getId(), t.getAmount(), t.getPrincipalAmount(), t.getInterestAmount(), t.getDate());
            if (t.getPrincipalAmount() != null) {
                totalPrincipal = totalPrincipal.add(t.getPrincipalAmount());
            }
        }
        logger.info("Total capital pagado para préstamo {}: {}", loanId, totalPrincipal);
        
        return transactions;
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
        logger.info("=== POST /api/transactions - Creando nueva transacción ===");
        logger.info("Request recibido: Type: {}, Amount: {}, Principal: {}, Interest: {}, Loan ID: {}",
            request.getType(), request.getAmount(), request.getPrincipalAmount(), 
            request.getInterestAmount(), request.getLoan() != null ? request.getLoan().getId() : "null");
        
        Transaction transaction = new Transaction();
        transaction.setType(request.getType());
        transaction.setAmount(request.getAmount());
        transaction.setPaymentMethod(request.getPaymentMethod());
        transaction.setNotes(request.getNotes());
        transaction.setInterestAmount(request.getInterestAmount());
        transaction.setPrincipalAmount(request.getPrincipalAmount());
        transaction.setValorRealCuota(request.getValorRealCuota());
        
        // Usar fecha enviada desde Flutter o fecha actual como fallback
        LocalDateTime transactionDate;
        if (request.getDate() != null) {
            transactionDate = request.getDate();
            logger.info("Usando fecha enviada desde Flutter: {}", transactionDate);
        } else {
            transactionDate = LocalDateTime.now();
            logger.info("Usando fecha del servidor como fallback: {}", transactionDate);
        }
        transaction.setDate(transactionDate);
        
        // Set loan reference
        if (request.getLoan() != null && request.getLoan().getId() != null) {
            Loan loan = new Loan();
            loan.setId(request.getLoan().getId());
            transaction.setLoan(loan);
            logger.info("Asignando préstamo ID: {} a la transacción", request.getLoan().getId());
        }
        
        Transaction savedTransaction = transactionService.saveWithLoan(transaction);
        logger.info("Transacción guardada con ID: {}, Amount: {}, Principal: {}, Fecha: {}", 
            savedTransaction.getId(), savedTransaction.getAmount(), savedTransaction.getPrincipalAmount(), savedTransaction.getDate());
        
        return savedTransaction;
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
    
    @GetMapping("/debug/datetime")
    public ResponseEntity<Map<String, Object>> debugDateTime() {
        Map<String, Object> debug = new java.util.HashMap<>();
        debug.put("LocalDateTime.now()", LocalDateTime.now());
        debug.put("LocalDate.now()", java.time.LocalDate.now());
        debug.put("System.currentTimeMillis()", System.currentTimeMillis());
        debug.put("new Date()", new java.util.Date());
        debug.put("ZoneId.systemDefault()", java.time.ZoneId.systemDefault().toString());
        debug.put("Year.now()", java.time.Year.now().getValue());
        debug.put("Month.now()", java.time.MonthDay.now().getMonth());
        debug.put("Day.now()", java.time.MonthDay.now().getDayOfMonth());
        
        logger.info("=== DEBUG FECHA/HORA ===");
        logger.info("LocalDateTime.now(): {}", LocalDateTime.now());
        logger.info("LocalDate.now(): {}", java.time.LocalDate.now());
        logger.info("ZoneId.systemDefault(): {}", java.time.ZoneId.systemDefault());
        logger.info("Year.now(): {}", java.time.Year.now().getValue());
        
        return ResponseEntity.ok(debug);
    }
    public ResponseEntity<Map<String, Object>> debugAllTransactions() {
        logger.info("=== DEBUG: Analizando todas las transacciones ===");
        List<Transaction> transactions = transactionService.findAll();
        
        Map<String, Object> debug = new java.util.HashMap<>();
        debug.put("totalTransactions", transactions.size());
        debug.put("serverDateTime", LocalDateTime.now());
        debug.put("serverDate", LocalDateTime.now().toLocalDate());
        debug.put("systemDate", java.time.LocalDate.now());
        debug.put("systemDateTime", java.time.LocalDateTime.now());
        debug.put("timeZone", java.time.ZoneId.systemDefault().toString());
        debug.put("currentYear", java.time.Year.now().getValue());
        
        BigDecimal totalAmount = BigDecimal.ZERO;
        BigDecimal totalPrincipal = BigDecimal.ZERO;
        BigDecimal totalInterest = BigDecimal.ZERO;
        int transactionsWithPrincipal = 0;
        int transactionsWithoutPrincipal = 0;
        
        for (Transaction t : transactions) {
            if (t.getAmount() != null) totalAmount = totalAmount.add(t.getAmount());
            if (t.getPrincipalAmount() != null) {
                totalPrincipal = totalPrincipal.add(t.getPrincipalAmount());
                transactionsWithPrincipal++;
            } else {
                transactionsWithoutPrincipal++;
            }
            if (t.getInterestAmount() != null) totalInterest = totalInterest.add(t.getInterestAmount());
        }
        
        debug.put("totalAmount", totalAmount);
        debug.put("totalPrincipal", totalPrincipal);
        debug.put("totalInterest", totalInterest);
        debug.put("transactionsWithPrincipal", transactionsWithPrincipal);
        debug.put("transactionsWithoutPrincipal", transactionsWithoutPrincipal);
        debug.put("transactions", transactions);
        
        logger.info("Fecha/hora del servidor: {}", LocalDateTime.now());
        logger.info("Total transacciones: {}, Con principal: {}, Sin principal: {}", 
            transactions.size(), transactionsWithPrincipal, transactionsWithoutPrincipal);
        logger.info("Total amount: {}, Total principal: {}, Total interest: {}", 
            totalAmount, totalPrincipal, totalInterest);
        
        return ResponseEntity.ok(debug);
    }
    
    @PostMapping("/fix-principal-amounts")
    public ResponseEntity<Map<String, Object>> fixPrincipalAmounts() {
        List<Transaction> allTransactions = transactionService.findAll();
        int fixedCount = 0;
        
        for (Transaction transaction : allTransactions) {
            // Solo corregir transacciones que tienen principalAmount diferente al amount
            if (transaction.getPrincipalAmount() != null && 
                transaction.getAmount() != null &&
                transaction.getPrincipalAmount().compareTo(transaction.getAmount()) != 0) {
                
                // Corregir: principalAmount debe ser igual al amount total
                transaction.setPrincipalAmount(transaction.getAmount());
                transactionService.save(transaction);
                fixedCount++;
            }
        }
        
        Map<String, Object> result = new java.util.HashMap<>();
        result.put("message", "Transacciones corregidas exitosamente");
        result.put("totalTransactions", allTransactions.size());
        result.put("fixedTransactions", fixedCount);
        
        return ResponseEntity.ok(result);
    }
}