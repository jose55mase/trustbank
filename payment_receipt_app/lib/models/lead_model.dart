import 'package:equatable/equatable.dart';

/// Lead model for the supervisor module.
/// All fields (except id) are nullable to support partial updates.
class LeadModel extends Equatable {
  final int id;
  final String? nombre;
  final String? apellido;
  final String? telefono;
  final String? email;
  final String? pais;
  final String? campana;
  final String? lastCallStatus;
  final String? comentarios;
  final DateTime? fechaRegistro;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? advisorId;
  final String? advisorName;

  const LeadModel({
    required this.id,
    this.nombre,
    this.apellido,
    this.telefono,
    this.email,
    this.pais,
    this.campana,
    this.lastCallStatus,
    this.comentarios,
    this.fechaRegistro,
    this.createdAt,
    this.updatedAt,
    this.advisorId,
    this.advisorName,
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
      id: json['id'] as int,
      nombre: json['nombre'] as String?,
      apellido: json['apellido'] as String?,
      telefono: json['telefono'] as String?,
      email: json['email'] as String?,
      pais: json['pais'] as String?,
      campana: json['campana'] as String?,
      lastCallStatus: json['lastCallStatus'] as String?,
      comentarios: json['comentarios'] as String?,
      fechaRegistro: _parseDate(json['fechaRegistro']),
      createdAt: _parseDate(json['createdAt']),
      updatedAt: _parseDate(json['updatedAt']),
      advisorId: advisorId,
      advisorName: advisorName,
    );
  }

  /// Returns a map with only the editable fields that have a non-null value.
  /// Excludes id, fechaRegistro, createdAt, updatedAt (non-editable fields).
  Map<String, dynamic> toEditJson() {
    final map = <String, dynamic>{};
    if (nombre != null) map['nombre'] = nombre;
    if (apellido != null) map['apellido'] = apellido;
    if (telefono != null) map['telefono'] = telefono;
    if (email != null) map['email'] = email;
    if (pais != null) map['pais'] = pais;
    if (campana != null) map['campana'] = campana;
    if (lastCallStatus != null) map['lastCallStatus'] = lastCallStatus;
    if (comentarios != null) map['comentarios'] = comentarios;
    return map;
  }

  static DateTime? _parseDate(dynamic dateValue) {
    if (dateValue == null) return null;
    try {
      return DateTime.parse(dateValue.toString());
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
        id,
        nombre,
        apellido,
        telefono,
        email,
        pais,
        campana,
        lastCallStatus,
        comentarios,
        fechaRegistro,
        createdAt,
        updatedAt,
        advisorId,
        advisorName,
      ];
}
