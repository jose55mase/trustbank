import 'loan_status.dart';

class Loan {
  final String id;
  final String userId;
  final double amount;
  final double interestRate;
  final int installments;
  final int paidInstallments;
  final DateTime startDate;
  final LoanStatus status;
  final bool pagoAnterior;
  final bool pagoActual;
  final double remainingAmount;
  final String? loanType;
  final String? paymentFrequency;
  final double? valorRealCuota;
  final double? backendInstallmentAmount;

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.interestRate,
    required this.installments,
    required this.paidInstallments,
    required this.startDate,
    required this.status,
    required this.remainingAmount,
    this.pagoAnterior = false,
    this.pagoActual = false,
    this.loanType,
    this.paymentFrequency,
    this.valorRealCuota,
    this.backendInstallmentAmount,
  });

  factory Loan.fromJson(Map<String, dynamic> json) {
    return Loan(
      id: json['id'].toString(),
      userId: json['user']['id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      interestRate: (json['interestRate'] as num).toDouble(),
      installments: json['installments'] as int,
      paidInstallments: json['paidInstallments'] as int,
      startDate: DateTime.parse(json['startDate']),
      status: _parseStatus(json['status']),
      remainingAmount: (json['remainingAmount'] as num).toDouble(),
      pagoAnterior: json['pagoAnterior'] ?? false,
      pagoActual: json['pagoActual'] ?? false,
      loanType: json['loanType'],
      paymentFrequency: json['paymentFrequency'],
      valorRealCuota: json['valorRealCuota'] != null ? (json['valorRealCuota'] as num).toDouble() : null,
      backendInstallmentAmount: json['installmentAmount'] != null ? (json['installmentAmount'] as num).toDouble() : null,
    );
  }

  static LoanStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return LoanStatus.active;
      case 'completed':
        return LoanStatus.completed;
      case 'overdue':
        return LoanStatus.overdue;
      default:
        return LoanStatus.active;
    }
  }

  // Cálculo basado en el tipo de préstamo
  double get totalAmount {
    if (loanType == 'Fijo') {
      // Para préstamos fijos: monto + (tasa de interés * cantidad de cuotas)
      return amount + (amount * interestRate / 100 * installments);
    } else if (loanType == 'Rotativo') {
      // Para préstamos rotativos: monto + interés sobre monto restante
      return amount + (remainingAmount * interestRate / 100);
    } else {
      // Para otros tipos: monto + (monto * tasa de interés / 100)
      return amount + (amount * interestRate / 100);
    }
  }
  
  double get installmentAmount {
    if (loanType == 'Fijo') {
      // Para préstamos fijos: valor por cuota es la tasa de interés mensual
      return amount * interestRate / 100;
    } else if (loanType == 'Rotativo') {
      // Para préstamos rotativos: cuota basada en monto restante
      return remainingAmount / (installments - paidInstallments).clamp(1, installments);
    } else {
      // Para otros tipos: total dividido entre cuotas
      return totalAmount / installments;
    }
  }
  
  double get profit {
    if (loanType == 'Fijo') {
      // Para préstamos fijos: ganancia total es tasa * cuotas
      return amount * interestRate / 100 * installments;
    } else if (loanType == 'Rotativo') {
      // Para préstamos rotativos: ganancia sobre monto restante
      return remainingAmount * interestRate / 100;
    } else {
      // Para otros tipos: ganancia simple
      return amount * interestRate / 100;
    }
  }
  
  // Método para calcular el interés de la próxima cuota (específico para rotativos)
  double get nextInstallmentInterest {
    if (loanType == 'Rotativo') {
      return remainingAmount * interestRate / 100;
    }
    return 0.0;
  }
}
