class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? documentType;
  final String? documentNumber;
  final String accountStatus;
  final double balance;
  final DateTime createdAt;
  final DateTime? updatedAt;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.documentType,
    this.documentNumber,
    required this.accountStatus,
    required this.balance,
    required this.createdAt,
    this.updatedAt,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['firstName'] ?? json['username'] ?? 'Usuario',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      accountStatus: json['accountStatus'] ?? 'ACTIVE',
      balance: _parseBalance(json),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
    );
  }

  static double _parseBalance(Map<String, dynamic> json) {
    final moneyclean = json['moneyclean'];
    final balance = json['balance'];
    
    if (moneyclean != null) {
      return double.tryParse(moneyclean.toString()) ?? 0.0;
    }
    if (balance != null) {
      return double.tryParse(balance.toString()) ?? 0.0;
    }
    return 0.0;
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'accountStatus': accountStatus,
      'moneyclean': balance,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  AdminUser copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? address,
    String? documentType,
    String? documentNumber,
    String? accountStatus,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      accountStatus: accountStatus ?? this.accountStatus,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum UserStatus {
  active,
  inactive,
  pending,
  suspended,
}