package com.trustbank.loans.backend.apirest.service;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

@Service
public class ScheduledOverdueService {

    @Autowired
    private OverdueLoanService overdueLoanService;

    // Ejecutar todos los días a las 6:00 AM
    @Scheduled(cron = "0 0 6 * * ?")
    public void checkOverdueLoansDaily() {
        System.out.println("Ejecutando verificación diaria de préstamos vencidos...");
        var overdueLoans = overdueLoanService.checkOverdueLoans();
        System.out.println("Préstamos marcados como vencidos: " + overdueLoans.size());
    }

    // Ejecutar cada hora durante horario laboral (8 AM - 6 PM)
    @Scheduled(cron = "0 0 8-18 * * MON-FRI")
    public void checkOverdueLoansHourly() {
        System.out.println("Verificación horaria de préstamos vencidos...");
        overdueLoanService.checkOverdueLoans();
    }
}