import 'package:equatable/equatable.dart';

class AssignmentType extends Equatable {
  final int id;
  final String name;
  final String description;
  final bool active;
  final String? filterValue;
  final int supervisorCount;
  final DateTime? createdAt;

  const AssignmentType({
    required this.id,
    required this.name,
    required this.description,
    required this.active,
    this.filterValue,
    required this.supervisorCount,
    this.createdAt,
  });

  factory AssignmentType.fromJson(Map<String, dynamic> json) {
    return AssignmentType(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      active: json['active'] as bool? ?? true,
      filterValue: json['filterValue'] as String?,
      supervisorCount: json['supervisorCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'active': active,
      'filterValue': filterValue,
      'supervisorCount': supervisorCount,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        active,
        filterValue,
        supervisorCount,
        createdAt,
      ];
}
