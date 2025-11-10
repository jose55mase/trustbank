enum RequestType { sendMoney, recharge, credit }
enum RequestStatus { pending, approved, rejected }

class AdminRequest {
  final String id;
  final RequestType type;
  final RequestStatus status;
  final String userId;
  final String userName;
  final double amount;
  final String details;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? adminNotes;

  AdminRequest({
    required this.id,
    required this.type,
    required this.status,
    required this.userId,
    required this.userName,
    required this.amount,
    required this.details,
    required this.createdAt,
    this.processedAt,
    this.adminNotes,
  });

  AdminRequest copyWith({
    RequestStatus? status,
    DateTime? processedAt,
    String? adminNotes,
  }) {
    return AdminRequest(
      id: id,
      type: type,
      status: status ?? this.status,
      userId: userId,
      userName: userName,
      amount: amount,
      details: details,
      createdAt: createdAt,
      processedAt: processedAt ?? this.processedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  String get typeLabel {
    switch (type) {
      case RequestType.sendMoney:
        return 'Envío';
      case RequestType.recharge:
        return 'Recarga';
      case RequestType.credit:
        return 'Crédito';
    }
  }

  String get statusLabel {
    switch (status) {
      case RequestStatus.pending:
        return 'Pendiente';
      case RequestStatus.approved:
        return 'Aprobado';
      case RequestStatus.rejected:
        return 'Rechazado';
    }
  }
}