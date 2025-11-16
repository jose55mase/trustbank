import '../../../models/user_role.dart';

class AdminUser {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final String? documentType;
  final String? documentNumber;
  final String? documentFront;
  final String? documentBack;
  final String? clientPhoto;
  final String accountStatus;
  final double balance;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Map<String, dynamic>> roles; // Backend RolEntity list

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.documentType,
    this.documentNumber,
    this.documentFront,
    this.documentBack,
    this.clientPhoto,
    required this.accountStatus,
    required this.balance,
    required this.createdAt,
    this.updatedAt,
    this.roles = const [],
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? 0,
      name: json['name'] ?? json['fistName'] ?? json['firstName'] ?? json['username'] ?? 'Usuario',
      email: json['email'] ?? '',
      phone: json['phone'],
      address: json['address'],
      documentType: json['documentType'],
      documentNumber: json['documentNumber'],
      documentFront: json['documentFrom'],
      documentBack: json['documentBack'],
      clientPhoto: json['foto'],
      accountStatus: json['accountStatus'] ?? 'ACTIVE',
      balance: _parseBalance(json),
      createdAt: _parseDate(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(json['updatedAt']),
      roles: _parseRoles(json['rols']),
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
  
  static List<Map<String, dynamic>> _parseRoles(dynamic rolesValue) {
    if (rolesValue == null) return [];
    if (rolesValue is List) {
      return rolesValue.map((role) => {
        'id': role['id'],
        'name': role['name'],
      }).toList().cast<Map<String, dynamic>>();
    }
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fistName': name, // Backend uses 'fistName'
      'email': email,
      'phone': phone,
      'address': address,
      'documentType': documentType,
      'documentNumber': documentNumber,
      'documentFrom': documentFront,
      'documentBack': documentBack,
      'foto': clientPhoto,
      'accountStatus': accountStatus,
      'moneyclean': balance.toInt(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'rols': roles,
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
    String? documentFront,
    String? documentBack,
    String? clientPhoto,
    String? accountStatus,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<Map<String, dynamic>>? roles,
  }) {
    return AdminUser(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      documentType: documentType ?? this.documentType,
      documentNumber: documentNumber ?? this.documentNumber,
      documentFront: documentFront ?? this.documentFront,
      documentBack: documentBack ?? this.documentBack,
      clientPhoto: clientPhoto ?? this.clientPhoto,
      accountStatus: accountStatus ?? this.accountStatus,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      roles: roles ?? this.roles,
    );
  }
  
  // Role-related helper methods
  UserRole get primaryRole {
    return UserRole.fromBackendRoles(roles);
  }
  
  bool hasRole(UserRole role) {
    return roles.any((r) => r['name'] == role.value);
  }
  
  List<String> get roleNames {
    return roles.map((r) => r['name']?.toString() ?? '').toList();
  }
  
  bool get isAdmin {
    return hasRole(UserRole.admin) || hasRole(UserRole.superAdmin) || hasRole(UserRole.moderator);
  }
}

enum UserStatus {
  active,
  inactive,
  pending,
  suspended,
}