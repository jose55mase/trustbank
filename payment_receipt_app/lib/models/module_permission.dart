import 'package:equatable/equatable.dart';

class ModulePermission extends Equatable {
  final int id;
  final String code;
  final String name;
  final String description;
  final String icon;
  final int displayOrder;

  const ModulePermission({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    required this.icon,
    required this.displayOrder,
  });

  factory ModulePermission.fromJson(Map<String, dynamic> json) {
    return ModulePermission(
      id: json['id'] as int,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      icon: json['icon'] as String? ?? '',
      displayOrder: json['displayOrder'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'name': name,
      'description': description,
      'icon': icon,
      'displayOrder': displayOrder,
    };
  }

  @override
  List<Object> get props => [id, code, name, description, icon, displayOrder];
}
