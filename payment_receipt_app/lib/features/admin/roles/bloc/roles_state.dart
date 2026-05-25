part of 'roles_bloc.dart';

abstract class RolesState {}

class RolesInitial extends RolesState {}

class RolesLoading extends RolesState {}

class RolesLoaded extends RolesState {
  final List<RoleModel> roles;
  final List<ModulePermission> allModules;

  RolesLoaded({
    required this.roles,
    required this.allModules,
  });
}

class RolesError extends RolesState {
  final String message;

  RolesError({required this.message});
}
