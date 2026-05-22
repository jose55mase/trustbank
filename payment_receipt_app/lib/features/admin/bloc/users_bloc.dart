import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../../../services/user_management_service.dart';

part 'users_event.dart';
part 'users_state.dart';

class UsersBloc extends Bloc<UsersEvent, UsersState> {
  List<AdminUser> _allUsers = [];

  UsersBloc() : super(UsersInitial()) {
    on<LoadUsers>(_onLoadUsers);
    on<LoadMoreUsers>(_onLoadMoreUsers);
    on<UpdateUserStatus>(_onUpdateUserStatus);
    on<FilterUsers>(_onFilterUsers);
    on<RefreshUsers>(_onRefreshUsers);
  }

  void _onLoadUsers(LoadUsers event, Emitter<UsersState> emit) async {
    try {
      emit(UsersLoading());
      _allUsers = await UserManagementService.getAllUsers();
      
      // Ordenar por fecha de creación descendente
      _allUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(UsersLoaded(
        users: _allUsers,
        hasMoreData: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onLoadMoreUsers(LoadMoreUsers event, Emitter<UsersState> emit) {
    // No pagination needed - all users loaded at once
  }

  void _onRefreshUsers(RefreshUsers event, Emitter<UsersState> emit) async {
    add(LoadUsers());
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<UsersState> emit) async {
    try {
      final statusString = event.status.name.toUpperCase();
      await UserManagementService.updateUserStatus(event.userId, statusString);
      add(LoadUsers());
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onFilterUsers(FilterUsers event, Emitter<UsersState> emit) async {
    try {
      // Si no tenemos usuarios cargados, cargarlos primero
      if (_allUsers.isEmpty) {
        _allUsers = await UserManagementService.getAllUsers();
        _allUsers.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      }

      List<AdminUser> filtered = List.from(_allUsers);

      // Filtrar por estado
      if (event.status != null) {
        final statusString = event.status!.name.toUpperCase();
        filtered = filtered.where((user) =>
            user.accountStatus.toUpperCase() == statusString).toList();
      }

      // Filtrar por búsqueda
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        final query = event.searchQuery!.toLowerCase();
        filtered = filtered.where((user) =>
            user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            (user.phone ?? '').contains(query)).toList();
      }

      emit(UsersLoaded(
        users: filtered,
        hasMoreData: false,
        isLoadingMore: false,
      ));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }
}
