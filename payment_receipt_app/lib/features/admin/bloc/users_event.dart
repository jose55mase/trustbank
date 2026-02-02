part of 'users_bloc.dart';

abstract class UsersEvent {}

class LoadUsers extends UsersEvent {}

class LoadMoreUsers extends UsersEvent {}

class RefreshUsers extends UsersEvent {}

class UpdateUserStatus extends UsersEvent {
  final int userId;
  final UserStatus status;

  UpdateUserStatus({required this.userId, required this.status});
}

class FilterUsers extends UsersEvent {
  final UserStatus? status;
  final String? searchQuery;

  FilterUsers({this.status, this.searchQuery});
}