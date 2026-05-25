import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/module_permission.dart';
import '../../../../models/role_model.dart';
import '../services/roles_service.dart';

part 'roles_event.dart';
part 'roles_state.dart';

class RolesBloc extends Bloc<RolesEvent, RolesState> {
  RolesBloc() : super(RolesInitial()) {
    on<LoadRoles>(_onLoadRoles);
    on<CreateRole>(_onCreateRole);
    on<UpdateRole>(_onUpdateRole);
    on<DeleteRole>(_onDeleteRole);
    on<UpdateRoleModules>(_onUpdateRoleModules);
  }

  Future<void> _onLoadRoles(LoadRoles event, Emitter<RolesState> emit) async {
    emit(RolesLoading());
    try {
      final roles = await RolesService.getRoles();
      final allModules = await RolesService.getModules();
      emit(RolesLoaded(roles: roles, allModules: allModules));
    } catch (e) {
      emit(RolesError(
        message: 'Error al cargar roles: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onCreateRole(
    CreateRole event,
    Emitter<RolesState> emit,
  ) async {
    emit(RolesLoading());
    try {
      await RolesService.createRole(event.name);
      add(LoadRoles());
    } catch (e) {
      emit(RolesError(
        message: 'Error al crear rol: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onUpdateRole(
    UpdateRole event,
    Emitter<RolesState> emit,
  ) async {
    emit(RolesLoading());
    try {
      await RolesService.updateRole(event.id, event.name);
      add(LoadRoles());
    } catch (e) {
      emit(RolesError(
        message: 'Error al actualizar rol: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onDeleteRole(
    DeleteRole event,
    Emitter<RolesState> emit,
  ) async {
    emit(RolesLoading());
    try {
      await RolesService.deleteRole(event.id);
      add(LoadRoles());
    } catch (e) {
      emit(RolesError(
        message: 'Error al eliminar rol: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onUpdateRoleModules(
    UpdateRoleModules event,
    Emitter<RolesState> emit,
  ) async {
    emit(RolesLoading());
    try {
      await RolesService.updateRoleModules(event.roleId, event.moduleIds);
      add(LoadRoles());
    } catch (e) {
      emit(RolesError(
        message: 'Error al actualizar módulos del rol: ${_parseErrorMessage(e)}',
      ));
    }
  }

  /// Extrae un mensaje legible de la excepción.
  String _parseErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
