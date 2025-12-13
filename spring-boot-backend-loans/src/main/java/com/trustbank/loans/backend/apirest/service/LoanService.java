package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import com.trustbank.loans.backend.apirest.entity.User;
import com.trustbank.loans.backend.apirest.repository.LoanRepository;
import com.trustbank.loans.backend.apirest.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.util.List;
import java.util.Optional;

@Service
public class LoanService {
    
    @Autowired
    private LoanRepository loanRepository;
    
    @Autowired
    private UserRepository userRepository;
    
    public List<Loan> findAll() {
        return loanRepository.findAll();
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
}