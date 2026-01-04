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
        
        System.out.println("=== VERIFICACIÓN DE PRÉSTAMOS VENCIDOS ===");
        System.out.println("Fecha actual: " + today);
        System.out.println("Préstamos activos encontrados: " + activeLoans.size());

        for (Loan loan : activeLoans) {
            LocalDate nextPaymentDate = calculateNextPaymentDate(loan);
            System.out.println("Préstamo ID: " + loan.getId() + 
                             ", Usuario: " + loan.getUser().getName() +
                             ", Fecha inicio: " + loan.getStartDate().toLocalDate() +
                             ", Cuotas pagadas: " + loan.getPaidInstallments() +
                             ", Frecuencia: " + loan.getPaymentFrequency() +
                             ", Próxima fecha pago: " + nextPaymentDate);
            
            if (nextPaymentDate != null && nextPaymentDate.isBefore(today)) {
                System.out.println("  -> MARCANDO COMO VENCIDO");
                // Marcar como vencido
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

    private LocalDate calculateNextPaymentDate(Loan loan) {
        LocalDate startDate = loan.getStartDate().toLocalDate();
        String paymentFrequency = loan.getPaymentFrequency();
        int paidInstallments = loan.getPaidInstallments();

        if (paidInstallments >= loan.getInstallments()) {
            return null; // Préstamo completamente pagado
        }

        // Calcular la fecha del próximo pago basado en cuotas pagadas
        int nextInstallmentNumber = paidInstallments + 1;

        switch (paymentFrequency) {
            case "Mensual 15":
                // Primera fecha: 15 del mes siguiente al préstamo
                return startDate.plusMonths(nextInstallmentNumber).withDayOfMonth(15);
                
            case "Mensual 30":
                // Primera fecha: 1 del segundo mes siguiente al préstamo
                return startDate.plusMonths(nextInstallmentNumber + 1).withDayOfMonth(1);
                
            case "Quincenal":
                // Alternar entre día 15 y día 1
                if (nextInstallmentNumber % 2 == 1) {
                    // Pago impar: día 15
                    int monthsToAdd = (nextInstallmentNumber - 1) / 2;
                    return startDate.plusMonths(monthsToAdd).withDayOfMonth(15);
                } else {
                    // Pago par: día 1 del siguiente mes
                    int monthsToAdd = nextInstallmentNumber / 2;
                    return startDate.plusMonths(monthsToAdd + 1).withDayOfMonth(1);
                }
                
            case "Quincenal 5":
                // Alternar entre día 5 y 20
                if (nextInstallmentNumber % 2 == 1) {
                    // Pago impar: día 5
                    int monthsToAdd = (nextInstallmentNumber - 1) / 2;
                    return startDate.plusMonths(monthsToAdd).withDayOfMonth(5);
                } else {
                    // Pago par: día 20
                    int monthsToAdd = (nextInstallmentNumber - 2) / 2;
                    return startDate.plusMonths(monthsToAdd).withDayOfMonth(20);
                }
                
            case "Quincenal 20":
                // Alternar entre día 20 y 5 del siguiente mes
                if (nextInstallmentNumber % 2 == 1) {
                    // Pago impar: día 20
                    int monthsToAdd = (nextInstallmentNumber - 1) / 2;
                    return startDate.plusMonths(monthsToAdd).withDayOfMonth(20);
                } else {
                    // Pago par: día 5 del siguiente mes
                    int monthsToAdd = nextInstallmentNumber / 2;
                    return startDate.plusMonths(monthsToAdd).withDayOfMonth(5);
                }
                
            case "Semanal":
                // Primera fecha: 7 días después del préstamo
                return startDate.plusWeeks(nextInstallmentNumber);
                
            default:
                return null;
        }
    }

    public int getOverdueLoansCount() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE).size();
    }

    public List<Loan> getOverdueLoans() {
        return loanRepository.findByStatus(LoanStatus.OVERDUE);
    }
}