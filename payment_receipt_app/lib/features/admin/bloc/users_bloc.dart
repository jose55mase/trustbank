import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../../../services/api_service.dart';

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
      final response = await ApiService.getAllUsers();
      final users = response.map((data) => AdminUser.fromJson(data)).toList();
      
      // Ordenar por fecha de creación descendente
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(UsersLoaded(users: users));
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onUpdateUserStatus(UpdateUserStatus event, Emitter<UsersState> emit) async {
    try {
      await ApiService.updateUserStatus(event.userId, event.status.name.toUpperCase());
      add(LoadUsers()); // Recargar usuarios
    } catch (e) {
      emit(UsersError(e.toString()));
    }
  }

  void _onFilterUsers(FilterUsers event, Emitter<UsersState> emit) {
    final currentState = state;
    if (currentState is UsersLoaded) {
      List<AdminUser> filteredUsers = currentState.users;
      
      if (event.status != null) {
        filteredUsers = filteredUsers.where((user) => 
          user.accountStatus.toLowerCase() == event.status!.name.toLowerCase()
        ).toList();
      }
      
      if (event.searchQuery != null && event.searchQuery!.isNotEmpty) {
        filteredUsers = filteredUsers.where((user) =>
          user.name.toLowerCase().contains(event.searchQuery!.toLowerCase()) ||
          user.email.toLowerCase().contains(event.searchQuery!.toLowerCase())
        ).toList();
      }
      
      emit(UsersLoaded(users: filteredUsers));
    }
  }
}