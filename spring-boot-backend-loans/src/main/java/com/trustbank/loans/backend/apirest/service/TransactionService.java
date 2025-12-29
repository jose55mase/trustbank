package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Transaction;
import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.repository.TransactionRepository;
import com.trustbank.loans.backend.apirest.repository.LoanRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Service
public class TransactionService {
    
    @Autowired
    private TransactionRepository transactionRepository;
    
    @Autowired
    private LoanRepository loanRepository;
    
    public List<Transaction> findAll() {
        return transactionRepository.findAllOrderByDateDesc();
    }
    
    public Optional<Transaction> findById(Long id) {
        return transactionRepository.findById(id);
    }
    
    public List<Transaction> findByLoanId(Long loanId) {
        return transactionRepository.findByLoanIdOrderByDateDesc(loanId);
    }
    
    public Transaction save(Transaction transaction) {
        return transactionRepository.save(transaction);
    }
    
    public Double getTotalPayments() {
        return transactionRepository.getTotalPayments();
    }
    
    public void deleteById(Long id) {
        transactionRepository.deleteById(id);
    }
    
    public Transaction saveWithLoan(Transaction transaction) {
        // Asegurar que el préstamo existe y está correctamente asociado
        
        if (transaction.getLoan() != null && transaction.getLoan().getId() != null) {
            Optional<Loan> loan = loanRepository.findById(transaction.getLoan().getId());
            if (loan.isPresent()) {
                transaction.setLoan(loan.get());
                
                // Si no se especifica principalAmount, usar el monto completo del pago
                // ya que los intereses se registran por separado en interestAmount
                if (transaction.getPrincipalAmount() == null) {
                    transaction.setPrincipalAmount(transaction.getAmount());
                }
                
                return transactionRepository.save(transaction);
            } else {
                throw new RuntimeException("Préstamo no encontrado con ID: " + transaction.getLoan().getId());
            }
        } else {
            throw new RuntimeException("ID del préstamo es requerido");
        }
    }
    
    public List<Transaction> findByDateRange(LocalDate startDate, LocalDate endDate) {
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);
        return transactionRepository.findByDateBetweenOrderByDateDesc(startDateTime, endDateTime);
    }
}