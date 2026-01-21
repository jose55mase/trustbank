package com.trustbank.loans.backend.apirest.service;

import com.trustbank.loans.backend.apirest.entity.Loan;
import com.trustbank.loans.backend.apirest.entity.LoanStatus;
import com.trustbank.loans.backend.apirest.repository.LoanRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class OverdueLoanService {

    @Autowired
    private LoanRepository loanRepository;

    public List<Loan> checkOverdueLoans() {
        List<Loan> activeLoans = loanRepository.findByStatus(LoanStatus.ACTIVE);
        List<Loan> overdueLoans = new ArrayList<>();
        LocalDateTime now = LocalDateTime.now();
        
        System.out.println("=== VERIFICACIÓN DE PRÉSTAMOS VENCIDOS ===");
        System.out.println("Fecha actual: " + now);
        System.out.println("Préstamos activos encontrados: " + activeLoans.size());

        for (Loan loan : activeLoans) {
            LocalDateTime nextPaymentDate = loan.getNextPaymentDate();
            System.out.println("Préstamo ID: " + loan.getId() + 
                             ", Usuario: " + loan.getUser().getName() +
                             ", Cuotas pagadas: " + loan.getPaidInstallments() +
                             ", Próxima fecha pago: " + nextPaymentDate);
            
            if (nextPaymentDate != null && nextPaymentDate.isBefore(now)) {
                System.out.println("  -> MARCANDO COMO VENCIDO");
                loan.setStatus(LoanStatus.OVERDUE);
                loan.setPreviousStatus(LoanStatus.ACTIVE);
                loan.setStatusChangeDate(LocalDateTime.now());
                loanRepository.save(loan);
                overdueLoans.add(loan);
            } else {
                System.out.println("  -> Aún no vencido");
            }
        }
        
        System.out.println("Total préstamos marcados como vencidos: " + overdueLoans.size());
        System.out.println("=== FIN VERIFICACIÓN ===");

        return overdueLoans;
    }

    public int getOverdueLoansCount() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE).size();
    }

    public List<Loan> getOverdueLoans() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE);
    }
}