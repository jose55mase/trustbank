part of 'roles_bloc.dart';

abstract class RolesEvent {}

class LoadRoles extends RolesEvent {}

class CreateRole extends RolesEvent {
  final String name;

  CreateRole({required this.name});
}

class UpdateRole extends RolesEvent {
  final int id;
  final String name;

  UpdateRole({required this.id, required this.name});
}

class DeleteRole extends RolesEvent {
  final int id;

  DeleteRole({required this.id});
}

class UpdateRoleModules extends RolesEvent {
  final int roleId;
  final List<int> moduleIds;

  UpdateRoleModules({required this.roleId, required this.moduleIds});
}
