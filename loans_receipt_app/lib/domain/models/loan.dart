class Loan {
  final String id;
  final String userId;
  final double amount;
  final double interestRate;
  final int installments;
  final int paidInstallments;
  final DateTime startDate;
  final LoanStatus status;

  Loan({
    required this.id,
    required this.userId,
    required this.amount,
    required this.interestRate,
    required this.installments,
    required this.paidInstallments,
    required this.startDate,
    required this.status,
  });

  double get totalAmount => amount + (amount * interestRate / 100);
  double get installmentAmount => totalAmount / installments;
  double get remainingAmount => installmentAmount * (installments - paidInstallments);
  double get profit => amount * interestRate / 100;
}

enum LoanStatus { active, completed, overdue }
