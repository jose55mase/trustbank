part of 'users_bloc.dart';

abstract class UsersState {}

class UsersInitial extends UsersState {}

class UsersLoading extends UsersState {}

class UsersLoaded extends UsersState {
  final List<AdminUser> users;
  final bool hasMoreData;
  final bool isLoadingMore;

  UsersLoaded({
    required this.users,
    this.hasMoreData = false,
    this.isLoadingMore = false,
  });
}

class UsersError extends UsersState {
  final String message;

  UsersError(this.message);
}