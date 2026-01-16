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
    
    public Loan save(Loan loan) {
        // Asegurar que el usuario existe y está correctamente asociado
        if (loan.getUser() != null && loan.getUser().getId() != null) {
            Optional<User> user = userRepository.findById(loan.getUser().getId());
            if (user.isPresent()) {
                loan.setUser(user.get());
            } else {
                throw new RuntimeException("Usuario no encontrado con ID: " + loan.getUser().getId());
            }
        }
        return loanRepository.save(loan);
    }
    
    public Double getTotalActiveLoanAmount() {
        return loanRepository.getTotalActiveLoanAmount();
    }
    
    public Double getTotalRemainingAmount() {
        List<Loan> activeLoans = loanRepository.findByStatus(LoanStatus.ACTIVE);
        return activeLoans.stream()
                .mapToDouble(loan -> loan.getRemainingAmount().doubleValue())
                .sum();
    }
    
    public Map<String, Object> recalculateAllBalances() {
        List<Loan> allLoans = loanRepository.findAll();
        int processedLoans = 0;
        int updatedLoans = 0;
        
        for (Loan loan : allLoans) {
            // Forzar recálculo del saldo restante
            BigDecimal oldRemaining = loan.getRemainingAmount();
            
            // El método getRemainingAmount() ya calcula basándose en las transacciones
            // Solo necesitamos guardar el préstamo para que se actualice
            BigDecimal newRemaining = loan.getRemainingAmount();
            
            // Actualizar estado si el préstamo está completamente pagado
            if (newRemaining.compareTo(BigDecimal.ZERO) <= 0 && loan.getStatus() == LoanStatus.ACTIVE) {
                loan.setStatus(LoanStatus.COMPLETED);
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