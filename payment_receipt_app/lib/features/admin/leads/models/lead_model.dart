class LeadModel {
  final int? id;
  final String nombre;
  final String apellido;
  final String lastCallStatus;
  final String pais;
  final String telefono;
  final String email;
  final String campana;
  final DateTime? fechaRegistro;
  final String comentarios;
  final int? importId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? advisorId;
  final String? advisorName;
  final DateTime? lastCallDate;
  final String? lastComment;

  LeadModel({
    this.id,
    required this.nombre,
    required this.apellido,
    required this.lastCallStatus,
    required this.pais,
    required this.telefono,
    required this.email,
    required this.campana,
    this.fechaRegistro,
    required this.comentarios,
    this.importId,
    this.createdAt,
    this.updatedAt,
    this.advisorId,
    this.advisorName,
    this.lastCallDate,
    this.lastComment,
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    final advisor = json['advisor'] as Map<String, dynamic>?;
    String? advisorName;
    int? advisorId;

    if (advisor != null) {
      advisorId = advisor['id'] as int?;
      final nombre = advisor['fistName'] as String? ?? advisor['firstName'] as String? ?? '';
      final apellido = advisor['lastName'] as String? ?? '';
      advisorName = '$nombre $apellido'.trim();
      if (advisorName.isEmpty) advisorName = null;
    }

    return LeadModel(
      id: json['id'],
      nombre: json['nombre'] ?? '',
      apellido: json['apellido'] ?? '',
      lastCallStatus: json['lastCallStatus'] ?? '',
      pais: json['pais'] ?? '',
      telefono: json['telefono'] ?? '',
      email: json['email'] ?? '',
      campana: json['campana'] ?? '',
      fechaRegistro: _parseDate(json['fechaRegistro']),
      comentarios: json['comentarios'] ?? '',
      importId: json['importId'],
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      advisorId: advisorId,
      advisorName: advisorName,
      lastCallDate: _parseDate(json['lastCallDate']),
      lastComment: json['lastComment'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'apellido': apellido,
      'lastCallStatus': lastCallStatus,
      'pais': pais,
      'telefono': telefono,
      'email': email,
      'campana': campana,
      'fechaRegistro': fechaRegistro?.toIso8601String(),
      'comentarios': comentarios,
      'importId': importId,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastCallDate': lastCallDate?.toIso8601String(),
      if (advisorId != null)
        'advisor': {
          'id': advisorId,
          'nombre': advisorName,
        },
    };
  }

  LeadModel copyWith({
    int? id,
    String? nombre,
    String? apellido,
    String? lastCallStatus,
    String? pais,
    String? telefono,
    String? email,
    String? campana,
    DateTime? fechaRegistro,
    String? comentarios,
    int? importId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? advisorId,
    String? advisorName,
    DateTime? lastCallDate,
    String? lastComment,
  }) {
    return LeadModel(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      apellido: apellido ?? this.apellido,
      lastCallStatus: lastCallStatus ?? this.lastCallStatus,
      pais: pais ?? this.pais,
      telefono: telefono ?? this.telefono,
      email: email ?? this.email,
      campana: campana ?? this.campana,
      fechaRegistro: fechaRegistro ?? this.fechaRegistro,
      comentarios: comentarios ?? this.comentarios,
      importId: importId ?? this.importId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      advisorId: advisorId ?? this.advisorId,
      advisorName: advisorName ?? this.advisorName,
      lastCallDate: lastCallDate ?? this.lastCallDate,
      lastComment: lastComment ?? this.lastComment,
    );
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (e) {
      return null;
    }
  }
}
