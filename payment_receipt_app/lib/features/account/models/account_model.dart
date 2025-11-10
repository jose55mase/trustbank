enum AccountStatus { pending, verified, rejected, suspended }
enum DocumentType { id, proofOfAddress, incomeProof, bankStatement }
enum DocumentStatus { pending, approved, rejected }

class UserAccount {
  final String userId;
  final String userName;
  final String email;
  final AccountStatus status;
  final List<UserDocument> documents;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  UserAccount({
    required this.userId,
    required this.userName,
    required this.email,
    required this.status,
    required this.documents,
    required this.createdAt,
    this.verifiedAt,
  });

  UserAccount copyWith({
    AccountStatus? status,
    List<UserDocument>? documents,
    DateTime? verifiedAt,
  }) {
    return UserAccount(
      userId: userId,
      userName: userName,
      email: email,
      status: status ?? this.status,
      documents: documents ?? this.documents,
      createdAt: createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
    );
  }

  String get statusLabel {
    switch (status) {
      case AccountStatus.pending:
        return 'Pendiente verificación';
      case AccountStatus.verified:
        return 'Verificada';
      case AccountStatus.rejected:
        return 'Rechazada';
      case AccountStatus.suspended:
        return 'Suspendida';
    }
  }
}

class UserDocument {
  final String id;
  final DocumentType type;
  final String fileName;
  final String filePath;
  final DocumentStatus status;
  final DateTime uploadedAt;
  final DateTime? processedAt;
  final String? adminNotes;

  UserDocument({
    required this.id,
    required this.type,
    required this.fileName,
    required this.filePath,
    required this.status,
    required this.uploadedAt,
    this.processedAt,
    this.adminNotes,
  });

  UserDocument copyWith({
    DocumentStatus? status,
    DateTime? processedAt,
    String? adminNotes,
  }) {
    return UserDocument(
      id: id,
      type: type,
      fileName: fileName,
      filePath: filePath,
      status: status ?? this.status,
      uploadedAt: uploadedAt,
      processedAt: processedAt ?? this.processedAt,
      adminNotes: adminNotes ?? this.adminNotes,
    );
  }

  String get typeLabel {
    switch (type) {
      case DocumentType.id:
        return 'Cédula/Pasaporte';
      case DocumentType.proofOfAddress:
        return 'Comprobante domicilio';
      case DocumentType.incomeProof:
        return 'Comprobante ingresos';
      case DocumentType.bankStatement:
        return 'Estado de cuenta';
    }
  }

  String get statusLabel {
    switch (status) {
      case DocumentStatus.pending:
        return 'Pendiente';
      case DocumentStatus.approved:
        return 'Aprobado';
      case DocumentStatus.rejected:
        return 'Rechazado';
    }
  }
}