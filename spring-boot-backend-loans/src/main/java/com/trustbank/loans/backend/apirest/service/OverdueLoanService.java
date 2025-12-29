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
        LocalDate today = LocalDate.now();

        for (Loan loan : activeLoans) {
            LocalDate nextPaymentDate = calculateNextPaymentDate(loan);
            if (nextPaymentDate != null && nextPaymentDate.isBefore(today)) {
                // Marcar como vencido
                loan.setStatus(LoanStatus.OVERDUE);
                loan.setPreviousStatus(LoanStatus.ACTIVE);
                loan.setStatusChangeDate(LocalDateTime.now());
                loanRepository.save(loan);
                overdueLoans.add(loan);
            }
        }

        return overdueLoans;
    }

    private LocalDate calculateNextPaymentDate(Loan loan) {
        LocalDate startDate = loan.getStartDate().toLocalDate();
        String paymentFrequency = loan.getPaymentFrequency();
        int paidInstallments = loan.getPaidInstallments();

        if (paidInstallments >= loan.getInstallments()) {
            return null; // Préstamo completamente pagado
        }

        switch (paymentFrequency) {
            case "Mensual 15":
                return startDate.plusMonths(paidInstallments + 1).withDayOfMonth(15);
                
            case "Mensual 30":
                return startDate.plusMonths(paidInstallments + 2).withDayOfMonth(1);
                
            case "Quincenal":
                return startDate.plusMonths(paidInstallments + 1).withDayOfMonth(15);
                
            case "Quincenal 5":
                return calculateQuincenal5Date(startDate, paidInstallments);
                
            case "Quincenal 20":
                return calculateQuincenal20Date(startDate, paidInstallments);
                
            case "Semanal":
                return startDate.plusWeeks(paidInstallments + 1);
                
            default:
                return null;
        }
    }

    private LocalDate calculateQuincenal5Date(LocalDate startDate, int paidInstallments) {
        LocalDate currentDate = startDate;
        for (int i = 0; i <= paidInstallments; i++) {
            if (i % 2 == 0) {
                // Día 5
                if (currentDate.getDayOfMonth() <= 5) {
                    currentDate = currentDate.withDayOfMonth(5);
                } else {
                    currentDate = currentDate.plusMonths(1).withDayOfMonth(5);
                }
            } else {
                // Día 20
                if (currentDate.getDayOfMonth() <= 20) {
                    currentDate = currentDate.withDayOfMonth(20);
                } else {
                    currentDate = currentDate.plusMonths(1).withDayOfMonth(20);
                }
            }
        }
        return currentDate;
    }

    private LocalDate calculateQuincenal20Date(LocalDate startDate, int paidInstallments) {
        LocalDate currentDate = startDate;
        for (int i = 0; i <= paidInstallments; i++) {
            if (i % 2 == 0) {
                // Día 20
                if (currentDate.getDayOfMonth() <= 20) {
                    currentDate = currentDate.withDayOfMonth(20);
                } else {
                    currentDate = currentDate.plusMonths(1).withDayOfMonth(20);
                }
            } else {
                // Día 5 del siguiente mes
                currentDate = currentDate.plusMonths(1).withDayOfMonth(5);
            }
        }
        return currentDate;
    }

    public int getOverdueLoansCount() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE).size();
    }

    public List<Loan> getOverdueLoans() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE);
    }
}