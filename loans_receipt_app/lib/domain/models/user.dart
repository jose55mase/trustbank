class User {
  final String id;
  final String name;
  final String userCode;
  final String phone;
  final String direccion;
  final String? referenceName;
  final String? referencePhone;
  final DateTime registrationDate;

  User({
    required this.id,
    required this.name,
    required this.userCode,
    required this.phone,
    required this.direccion,
    this.referenceName,
    this.referencePhone,
    required this.registrationDate,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id']?.toString() ?? '0',
      name: json['name'] ?? 'Sin nombre',
      userCode: json['userCode'] ?? 'N/A',
      phone: json['phone'] ?? 'N/A',
      direccion: json['direccion'] ?? 'N/A',
      referenceName: json['referenceName'],
      referencePhone: json['referencePhone'],
      registrationDate: json['registrationDate'] != null 
          ? DateTime.parse(json['registrationDate']) 
          : DateTime.now(),
    );
  }
}
