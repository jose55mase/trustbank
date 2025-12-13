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

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.interestRate,
    required this.installments,
    required this.paidInstallments,
    required this.startDate,
    required this.status,
    this.pagoAnterior = false,
    this.pagoActual = false,
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
      pagoAnterior: json['pagoAnterior'] ?? false,
      pagoActual: json['pagoActual'] ?? false,
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

  double get totalAmount => amount + (amount * interestRate / 100);
  double get installmentAmount => totalAmount / installments;
  double get remainingAmount => installmentAmount * (installments - paidInstallments);
  double get profit => amount * interestRate / 100;
}
