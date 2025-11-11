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
      id: json['id'],
      name: json['name'] ?? json['firstName'] ?? 'Usuario',
      email: json['email'],
      phone: json['phone'],
      address: json['address'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      accountStatus: json['accountStatus'] ?? 'ACTIVE',
      balance: (json['moneyclean'] ?? json['balance'] ?? 0.0).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
    );
  }
}

enum UserStatus {
  active,
  inactive,
  pending,
  suspended,
}