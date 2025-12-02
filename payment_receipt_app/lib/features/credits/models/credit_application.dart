enum CreditStatus {
  pending,
  underReview,
  approved,
  rejected,
  disbursed,
}

class CreditApplication {
  final int id;
  final String creditType;
  final double amount;
  final int termMonths;
  final double interestRate;
  final double monthlyPayment;
  final CreditStatus status;
  final DateTime applicationDate;
  final DateTime? reviewDate;
  final String? rejectionReason;
  final String? approvalComments;

  CreditApplication({
    required this.id,
    required this.creditType,
    required this.amount,
    required this.termMonths,
    required this.interestRate,
    required this.monthlyPayment,
    required this.status,
    required this.applicationDate,
    this.reviewDate,
    this.rejectionReason,
    this.approvalComments,
  });

  factory CreditApplication.fromJson(Map<String, dynamic> json) {
    return CreditApplication(
      id: json['id'],
      creditType: json['creditType'],
      amount: (json['amount'] ?? 0.0).toDouble(),
      termMonths: json['termMonths'],
      interestRate: (json['interestRate'] ?? 0.0).toDouble(),
      monthlyPayment: (json['monthlyPayment'] ?? 0.0).toDouble(),
      status: CreditStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CreditStatus.pending,
      ),
      applicationDate: DateTime.parse(json['applicationDate']),
      reviewDate: json['reviewDate'] != null ? DateTime.parse(json['reviewDate']) : null,
      rejectionReason: json['rejectionReason'],
      approvalComments: json['approvalComments'],
    );
  }

  String get statusText {
    switch (status) {
      case CreditStatus.pending:
        return 'Pendiente';
      case CreditStatus.underReview:
        return 'En revisión';
      case CreditStatus.approved:
        return 'Aprobado';
      case CreditStatus.rejected:
        return 'Rechazado';
      case CreditStatus.disbursed:
        return 'Desembolsado';
    }
  }

  String get statusDescription {
    switch (status) {
      case CreditStatus.pending:
        return 'Tu solicitud está en cola de revisión';
      case CreditStatus.underReview:
        return 'Estamos evaluando tu solicitud';
      case CreditStatus.approved:
        return '¡Felicidades! Tu crédito fue aprobado';
      case CreditStatus.rejected:
        return 'Tu solicitud no fue aprobada';
      case CreditStatus.disbursed:
        return 'El dinero ya está en tu cuenta';
    }
  }
}