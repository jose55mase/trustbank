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
            Optional<Loan> loanOpt = loanRepository.findById(transaction.getLoan().getId());
            if (loanOpt.isPresent()) {
                Loan loan = loanOpt.get();
                transaction.setLoan(loan);
                
                // Si no se especifica principalAmount, usar el monto completo del pago
                // ya que los intereses se registran por separado en interestAmount
                if (transaction.getPrincipalAmount() == null) {
                    transaction.setPrincipalAmount(transaction.getAmount());
                }
                
                // Guardar la transacción
                Transaction savedTransaction = transactionRepository.save(transaction);
                
                // Actualizar cuotas pagadas y estado del préstamo
                updateLoanProgress(loan);
                
                return savedTransaction;
            } else {
                throw new RuntimeException("Préstamo no encontrado con ID: " + transaction.getLoan().getId());
            }
        } else {
            throw new RuntimeException("ID del préstamo es requerido");
        }
    }
    
    private void updateLoanProgress(Loan loan) {
        Optional<Loan> loanOpt = loanRepository.findById(loan.getId());
        if (!loanOpt.isPresent()) return;
        
        Loan currentLoan = loanOpt.get();
        List<Transaction> payments = transactionRepository.findByLoanIdOrderByDateDesc(currentLoan.getId());
        int paymentCount = (int) payments.stream()
            .filter(t -> t.getPrincipalAmount() != null && t.getPrincipalAmount().compareTo(java.math.BigDecimal.ZERO) > 0)
            .count();
        
        currentLoan.setPaidInstallments(paymentCount);
        
        if (currentLoan.getNextPaymentDate() != null && currentLoan.getPaymentFrequency() != null) {
            currentLoan.setNextPaymentDate(calculateNextPaymentDate(currentLoan.getNextPaymentDate(), currentLoan.getPaymentFrequency()));
        }
        
        java.math.BigDecimal remainingAmount = currentLoan.getRemainingAmount();
        if (remainingAmount.compareTo(java.math.BigDecimal.ZERO) <= 0 || paymentCount >= currentLoan.getInstallments()) {
            currentLoan.setStatus(com.trustbank.loans.backend.apirest.entity.LoanStatus.COMPLETED);
        }
        
        loanRepository.save(currentLoan);
    }
    
    private LocalDateTime calculateNextPaymentDate(LocalDateTime currentDate, String frequency) {
        switch (frequency) {
            case "Mensual 15":
                return LocalDateTime.of(currentDate.getYear(), currentDate.getMonthValue() + 1, 15, 0, 0);
            case "Mensual 30":
                return currentDate.plusMonths(1).withDayOfMonth(1).minusDays(1);
            case "Quincenal":
                return currentDate.getDayOfMonth() == 15 
                    ? currentDate.plusMonths(1).withDayOfMonth(1).minusDays(1)
                    : currentDate.plusMonths(1).withDayOfMonth(15);
            case "Quincenal 5":
                return currentDate.getDayOfMonth() == 5
                    ? currentDate.withDayOfMonth(20)
                    : currentDate.plusMonths(1).withDayOfMonth(5);
            case "Quincenal 20":
                return currentDate.getDayOfMonth() == 20
                    ? currentDate.plusMonths(1).withDayOfMonth(5)
                    : currentDate.withDayOfMonth(20);
            case "Semanal":
                return currentDate.plusDays(7);
            default:
                return currentDate.plusMonths(1);
        }
    }
    
    public List<Transaction> findByDateRange(LocalDate startDate, LocalDate endDate) {
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);
        return transactionRepository.findByDateBetweenOrderByDateDesc(startDateTime, endDateTime);
    }
}