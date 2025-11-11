part of 'users_bloc.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<AdminUser> users;

  UsersLoaded({required this.users});
}

class UsersError extends UsersState {
  final String message;

  UsersError(this.message);
}