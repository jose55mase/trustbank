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
        
        System.out.println("=== ACTUALIZACIÓN DESPUÉS DE PAGO ===");
        System.out.println("Préstamo ID: " + currentLoan.getId());
        System.out.println("Frecuencia: " + currentLoan.getPaymentFrequency());
        System.out.println("Fecha actual nextPaymentDate: " + currentLoan.getNextPaymentDate());
        
        if (currentLoan.getNextPaymentDate() != null && currentLoan.getPaymentFrequency() != null) {
            java.time.LocalDateTime newNextPaymentDate = calculateNextPaymentDate(currentLoan.getNextPaymentDate(), currentLoan.getPaymentFrequency());
            System.out.println("Nueva nextPaymentDate calculada: " + newNextPaymentDate);
            currentLoan.setNextPaymentDate(newNextPaymentDate);
        }
        
        java.math.BigDecimal remainingAmount = currentLoan.getRemainingAmount();
        if (remainingAmount.compareTo(java.math.BigDecimal.ZERO) <= 0 || paymentCount >= currentLoan.getInstallments()) {
            currentLoan.setStatus(com.trustbank.loans.backend.apirest.entity.LoanStatus.COMPLETED);
        }
        
        loanRepository.save(currentLoan);
        System.out.println("=== FIN ACTUALIZACIÓN ===");
    }
    
    private LocalDateTime calculateNextPaymentDate(LocalDateTime currentDate, String frequency) {
        LocalDate current = currentDate.toLocalDate();
        LocalDate next;
        
        System.out.println("  -> Calculando desde fecha: " + current + " (día " + current.getDayOfMonth() + ")");
        
        switch (frequency) {
            case "Mensual 15":
                next = current.plusMonths(1).withDayOfMonth(15);
                break;
            case "Mensual 30":
                next = current.plusMonths(1);
                next = next.withDayOfMonth(next.lengthOfMonth());
                break;
            case "Quincenal":
                if (current.getDayOfMonth() == 15) {
                    // Si estamos en día 15, la siguiente es el último día del mes
                    next = current.withDayOfMonth(current.lengthOfMonth());
                } else {
                    // Si estamos en último día del mes, la siguiente es día 15 del siguiente mes
                    next = current.plusMonths(1).withDayOfMonth(15);
                }
                break;
            case "Quincenal 30-15":
                if (current.getDayOfMonth() >= current.lengthOfMonth() - 2) {
                    // Si estamos en el último día del mes (o cerca), la siguiente es día 15 del siguiente mes
                    next = current.plusMonths(1).withDayOfMonth(15);
                } else {
                    // Si estamos en día 15, la siguiente es el último día del mismo mes
                    next = current.withDayOfMonth(current.lengthOfMonth());
                }
                break;
            case "Quincenal 5":
                if (current.getDayOfMonth() == 5) {
                    next = current.withDayOfMonth(20);
                } else {
                    next = current.plusMonths(1).withDayOfMonth(5);
                }
                break;
            case "Quincenal 20":
                if (current.getDayOfMonth() == 20) {
                    next = current.plusMonths(1).withDayOfMonth(5);
                } else {
                    next = current.withDayOfMonth(20);
                    if (!next.isAfter(current)) {
                        next = next.plusMonths(1);
                    }
                }
                break;
            case "Semanal":
                next = current.plusWeeks(1);
                break;
            default:
                next = current.plusMonths(1);
        }
        
        System.out.println("  -> Próxima fecha calculada: " + next);
        return next.atStartOfDay();
    }
    
    public List<Transaction> findByDateRange(LocalDate startDate, LocalDate endDate) {
        LocalDateTime startDateTime = startDate.atStartOfDay();
        LocalDateTime endDateTime = endDate.atTime(23, 59, 59);
        return transactionRepository.findByDateBetweenOrderByDateDesc(startDateTime, endDateTime);
    }
}