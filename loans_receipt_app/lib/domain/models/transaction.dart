enum TransactionType { loan, payment }
enum PaymentMethod { cash, transfer, check }
enum LoanType { fixed, revolving }

class Transaction {
  final String id;
  final TransactionType type;
  final String userId;
  final String loanId;
  final double amount;
  final DateTime date;
  final PaymentMethod paymentMethod;
  final String? notes;
  final double? interestAmount;
  final double? principalAmount;
  final LoanType? loanType;

  Transaction({
    required this.id,
    required this.type,
    required this.userId,
    required this.loanId,
    required this.amount,
    required this.date,
    required this.paymentMethod,
    this.notes,
    this.interestAmount,
    this.principalAmount,
    this.loanType,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'userId': userId,
    'loanId': loanId,
    'amount': amount,
    'date': date.toIso8601String(),
    'paymentMethod': paymentMethod.name,
    'notes': notes,
    'interestAmount': interestAmount,
    'principalAmount': principalAmount,
    'loanType': loanType?.name,
  };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
    id: json['id'],
    type: TransactionType.values.byName(json['type']),
    userId: json['userId'],
    loanId: json['loanId'],
    amount: json['amount'].toDouble(),
    date: DateTime.parse(json['date']),
    paymentMethod: PaymentMethod.values.byName(json['paymentMethod']),
    notes: json['notes'],
    interestAmount: json['interestAmount']?.toDouble(),
    principalAmount: json['principalAmount']?.toDouble(),
    loanType: json['loanType'] != null ? LoanType.values.byName(json['loanType']) : null,
  );
}