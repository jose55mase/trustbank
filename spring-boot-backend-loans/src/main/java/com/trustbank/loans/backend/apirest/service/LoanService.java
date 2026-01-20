package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.repository.LoanRepository;
import com.trustbank.loans.backend.apirest.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
public class LoanService {
    
    @Autowired
    private LoanRepository loanRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    public List<Loan> findAll() {
        return loanRepository.findAllByOrderByIdDesc();
    }
    
    public Optional<Loan> findById(Long id) {
        return loanRepository.findById(id);
    }
    
    public List<Loan> findByUserId(Long userId) {
        return loanRepository.findByUserId(userId);
    }
    
    public List<Loan> findActiveAndOverdueLoansByUserId(Long userId) {
        List<Loan> allLoans = loanRepository.findByUserId(userId);
        return allLoans.stream()
            .filter(loan -> loan.getStatus() == LoanStatus.ACTIVE || loan.getStatus() == LoanStatus.OVERDUE)
            .collect(java.util.stream.Collectors.toList());
    }
    
    public List<Loan> findByStatus(LoanStatus status) {
        return loanRepository.findByStatus(status);
    }
    
    public List<Loan> findActiveAndOverdueLoans() {
        List<Loan> activeLoans = loanRepository.findByStatus(LoanStatus.ACTIVE);
        List<Loan> overdueLoans = loanRepository.findByStatus(LoanStatus.OVERDUE);
        activeLoans.addAll(overdueLoans);
        return activeLoans;
    }
    
    public Loan save(Loan loan) {
        if (loan.getUser() != null && loan.getUser().getId() != null) {
            Optional<User> user = userRepository.findById(loan.getUser().getId());
            if (user.isPresent()) {
                loan.setUser(user.get());
            } else {
                throw new RuntimeException("Usuario no encontrado con ID: " + loan.getUser().getId());
            }
        }
        
        // Calcular nextPaymentDate si es un préstamo nuevo
        if (loan.getId() == null && loan.getNextPaymentDate() == null && loan.getPaymentFrequency() != null) {
            loan.setNextPaymentDate(calculateFirstPaymentDate(loan.getStartDate(), loan.getPaymentFrequency()));
        }
        
        return loanRepository.save(loan);
    }
    
    private java.time.LocalDateTime calculateFirstPaymentDate(java.time.LocalDateTime startDate, String frequency) {
        java.time.LocalDate start = startDate.toLocalDate();
        java.time.LocalDate firstPayment;
        
        switch (frequency) {
            case "Mensual 15":
                if (start.getDayOfMonth() < 15) {
                    firstPayment = start.withDayOfMonth(15);
                } else {
                    firstPayment = start.plusMonths(1).withDayOfMonth(15);
                }
                break;
            case "Mensual 30":
                firstPayment = start.plusMonths(1).withDayOfMonth(start.plusMonths(1).lengthOfMonth());
                break;
            case "Quincenal":
                if (start.getDayOfMonth() < 15) {
                    firstPayment = start.withDayOfMonth(15);
                } else {
                    firstPayment = start.plusMonths(1).withDayOfMonth(15);
                }
                break;
            case "Quincenal 5":
                if (start.getDayOfMonth() < 5) {
                    firstPayment = start.withDayOfMonth(5);
                } else if (start.getDayOfMonth() < 20) {
                    firstPayment = start.withDayOfMonth(20);
                } else {
                    firstPayment = start.plusMonths(1).withDayOfMonth(5);
                }
                break;
            case "Quincenal 20":
                if (start.getDayOfMonth() < 20) {
                    firstPayment = start.withDayOfMonth(20);
                } else {
                    firstPayment = start.plusMonths(1).withDayOfMonth(5);
                }
                break;
            case "Semanal":
                firstPayment = start.plusWeeks(1);
                break;
            default:
                firstPayment = start.plusMonths(1);
        }
        
        System.out.println("=== CÁLCULO PRIMERA FECHA DE PAGO ===");
        System.out.println("Fecha inicio: " + start);
        System.out.println("Frecuencia: " + frequency);
        System.out.println("Primera fecha de pago: " + firstPayment);
        
        return firstPayment.atStartOfDay();
    }
    
    public Double getTotalActiveLoanAmount() {
        return loanRepository.getTotalActiveLoanAmount();
    }
    
    public Double getTotalRemainingAmount() {
        List<Loan> activeLoans = loanRepository.findByStatus(LoanStatus.ACTIVE);
        List<Loan> overdueLoans = loanRepository.findByStatus(LoanStatus.OVERDUE);
        
        double activeTotal = activeLoans.stream()
                .mapToDouble(loan -> loan.getRemainingAmount().doubleValue())
                .sum();
        
        double overdueTotal = overdueLoans.stream()
                .mapToDouble(loan -> loan.getRemainingAmount().doubleValue())
                .sum();
        
        return activeTotal + overdueTotal;
    }
    
    public Map<String, Object> recalculateAllBalances() {
        List<Loan> allLoans = loanRepository.findAll();
        int processedLoans = 0;
        int updatedLoans = 0;
        
        for (Loan loan : allLoans) {
            // Recalcular cuotas pagadas basándose en transacciones
            List<com.trustbank.loans.backend.apirest.entity.Transaction> payments = 
                loan.getTransactions() != null ? loan.getTransactions() : java.util.Collections.emptyList();
            
            int paymentCount = (int) payments.stream()
                .filter(t -> t.getPrincipalAmount() != null && t.getPrincipalAmount().compareTo(BigDecimal.ZERO) > 0)
                .count();
            
            int oldPaidInstallments = loan.getPaidInstallments();
            loan.setPaidInstallments(paymentCount);
            
            // Verificar si el préstamo está completamente pagado
            BigDecimal remainingAmount = loan.getRemainingAmount();
            LoanStatus oldStatus = loan.getStatus();
            
            if (remainingAmount.compareTo(BigDecimal.ZERO) <= 0 || paymentCount >= loan.getInstallments()) {
                if (loan.getStatus() == LoanStatus.ACTIVE) {
                    loan.setStatus(LoanStatus.COMPLETED);
                }
            }
            
            // Contar como actualizado si cambió algo
            if (oldPaidInstallments != paymentCount || !oldStatus.equals(loan.getStatus())) {
                updatedLoans++;
            }
            
            loanRepository.save(loan);
            processedLoans++;
        }
        
        Map<String, Object> result = new HashMap<>();
        result.put("processedLoans", processedLoans);
        result.put("updatedLoans", updatedLoans);
        result.put("message", "Recálculo completado exitosamente");
        
        return result;
    }
    
    public void deleteById(Long id) {
        loanRepository.deleteById(id);
    }
    
    public Loan updateStatus(Long id, LoanStatus newStatus) {
        Optional<Loan> loanOpt = loanRepository.findById(id);
        if (loanOpt.isPresent()) {
            Loan loan = loanOpt.get();
            loan.setStatus(newStatus); // Esto automáticamente guarda el estado anterior
            return loanRepository.save(loan);
        } else {
            throw new RuntimeException("Préstamo no encontrado con ID: " + id);
        }
    }
    
    public Loan updatePaymentStatus(Long id, Boolean pagoAnterior, Boolean pagoActual) {
        Optional<Loan> loanOpt = loanRepository.findById(id);
        if (loanOpt.isPresent()) {
            Loan loan = loanOpt.get();
            if (pagoAnterior != null) loan.setPagoAnterior(pagoAnterior);
            if (pagoActual != null) loan.setPagoActual(pagoActual);
            return loanRepository.save(loan);
        } else {
            throw new RuntimeException("Préstamo no encontrado con ID: " + id);
        }
    }
    
    public Loan updatePaidInstallments(Long id, Integer paidInstallments) {
        Optional<Loan> loanOpt = loanRepository.findById(id);
        if (loanOpt.isPresent()) {
            Loan loan = loanOpt.get();
            loan.setPaidInstallments(paidInstallments);
            return loanRepository.save(loan);
        } else {
            throw new RuntimeException("Préstamo no encontrado con ID: " + id);
        }
    }
    
    public List<Loan> findOverdueLoans() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE);
    }
    
    public Long countOverdueLoans() {
        return loanRepository.countByStatus(LoanStatus.OVERDUE);
    }
}