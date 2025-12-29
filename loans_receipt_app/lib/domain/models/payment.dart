class Payment {
  final String id;
  final String userId;
  final double amount;
  final String paymentMethod;
  final String? description;
  final double debtPayment;
  final double interestPayment;
  final DateTime paymentDate;
  final bool registered;

  Payment({
    required this.id,
    required this.userId,
    required this.amount,
    required this.paymentMethod,
    this.description,
    required this.debtPayment,
    required this.interestPayment,
    required this.paymentDate,
    this.registered = false,
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: json['id'].toString(),
      userId: json['user']['id'].toString(),
      amount: (json['amount'] as num).toDouble(),
      paymentMethod: json['paymentMethod'] as String,
      description: json['description'] as String?,
      debtPayment: (json['debtPayment'] as num).toDouble(),
      interestPayment: (json['interestPayment'] as num).toDouble(),
      paymentDate: DateTime.parse(json['paymentDate']),
      registered: json['registered'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': {'id': int.parse(userId)},
      'amount': amount,
      'paymentMethod': paymentMethod,
      'description': description,
      'debtPayment': debtPayment,
      'interestPayment': interestPayment,
      'registered': registered,
    };
  }
}