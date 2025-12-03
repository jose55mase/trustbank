class UserAccount {
  final int? id;
  final String? username;
  final String? email;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? address;
  final String? city;
  final String? country;
  final String? postal;
  final String? aboutme;
  final String? documentType;
  final String? documentNumber;
  final String? accountStatus;
  final int? balance;
  final bool? status;
  final String? foto;
  final String? documentFrom;
  final String? documentBack;
  final String? fotoStatus;
  final String? documentFromStatus;
  final String? documentBackStatus;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserAccount({
    this.id,
    this.username,
    this.email,
    this.firstName,
    this.lastName,
    this.phone,
    this.address,
    this.city,
    this.country,
    this.postal,
    this.aboutme,
    this.documentType,
    this.documentNumber,
    this.accountStatus,
    this.balance,
    this.status,
    this.foto,
    this.documentFrom,
    this.documentBack,
    this.fotoStatus,
    this.documentFromStatus,
    this.documentBackStatus,
    this.createdAt,
    this.updatedAt,
  });

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      firstName: json['fistName'], // Note: backend uses 'fistName'
      lastName: json['lastName'],
      phone: json['phone'],
      address: json['address'],
      city: json['city'],
      country: json['country'],
      postal: json['postal'],
      aboutme: json['aboutme'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      accountStatus: json['accountStatus'],
      balance: json['moneyclean'],
      status: json['status'],
      foto: json['foto'],
      documentFrom: json['documentFrom'],
      documentBack: json['documentBack'],
      fotoStatus: json['fotoStatus'],
      documentFromStatus: json['documentFromStatus'],
      documentBackStatus: json['documentBackStatus'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'fistName': firstName,
      'lastName': lastName,
      'phone': phone,
      'address': address,
      'city': city,
      'country': country,
      'postal': postal,
      'aboutme': aboutme,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'accountStatus': accountStatus,
      'moneyclean': balance,
      'status': status,
      'foto': foto,
      'documentFrom': documentFrom,
      'documentBack': documentBack,
      'fotoStatus': fotoStatus,
      'documentFromStatus': documentFromStatus,
      'documentBackStatus': documentBackStatus,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get fullName => '${firstName ?? ''} ${lastName ?? ''}'.trim();
  
  String get statusLabel {
    switch (accountStatus?.toUpperCase()) {
      case 'ACTIVE':
        return 'Activa';
      case 'SUSPENDED':
        return 'Suspendida';
      case 'PENDING':
        return 'Pendiente';
      default:
        return 'Desconocido';
    }
  }

  UserAccount copyWith({
    String? fotoStatus,
    String? documentFromStatus,
    String? documentBackStatus,
    String? accountStatus,
  }) {
    return UserAccount(
      id: id,
      username: username,
      email: email,
      firstName: firstName,
      lastName: lastName,
      phone: phone,
      address: address,
      city: city,
      country: country,
      postal: postal,
      aboutme: aboutme,
      documentType: documentType,
      documentNumber: documentNumber,
      accountStatus: accountStatus ?? this.accountStatus,
      balance: balance,
      status: status,
      foto: foto,
      documentFrom: documentFrom,
      documentBack: documentBack,
      fotoStatus: fotoStatus ?? this.fotoStatus,
      documentFromStatus: documentFromStatus ?? this.documentFromStatus,
      documentBackStatus: documentBackStatus ?? this.documentBackStatus,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

enum DocumentStatus { pending, approved, rejected }

class UserDocument {
  final String id;
  final String type;
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