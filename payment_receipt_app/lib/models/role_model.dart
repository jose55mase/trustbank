import 'package:equatable/equatable.dart';

import 'module_permission.dart';

class RoleModel extends Equatable {
  final int id;
  final String name;
  final List<ModulePermission> modules;
  final int userCount;

  const RoleModel({
    required this.id,
    required this.name,
    required this.modules,
    required this.userCount,
  });

  factory RoleModel.fromJson(Map<String, dynamic> json) {
    return RoleModel(
      id: json['id'] as int,
      name: json['name'] as String,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((m) => ModulePermission.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      userCount: json['userCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'modules': modules.map((m) => m.toJson()).toList(),
      'userCount': userCount,
    };
  }

  @override
  List<Object> get props => [id, name, modules, userCount];
}
