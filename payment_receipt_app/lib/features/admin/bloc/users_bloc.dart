import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../../../services/user_management_service.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  UsersBloc() : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<FilterUsers>(_onFilterUsers);
  }

  void _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final users = await UserManagementService.getAllUsers();
      
      // Ordenar por fecha de creación descendente
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<UsersState> emit) async {
    try {
      final statusString = event.status.name.toUpperCase();
      await UserManagementService.updateUserStatus(event.userId, statusString);
      add(LoadUsers()); // Recargar usuarios
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onFilterUsers(FilterUsers event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      final statusString = event.status?.name.toUpperCase();
      final users = await UserManagementService.filterUsers(
        status: statusString,
        searchQuery: event.searchQuery,
      );
      
      // Ordenar por fecha de creación descendente
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}