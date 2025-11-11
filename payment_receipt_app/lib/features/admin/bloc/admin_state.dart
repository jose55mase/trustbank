part of 'admin_bloc.dart';

abstract class AdminState {}

class AdminInitial extends AdminState {}

class AdminLoading extends AdminState {}

class AdminLoaded extends AdminState {
  final List<AdminRequest> requests;

  AdminLoaded({required this.requests});
}

class AdminError extends AdminState {
  final String message;
  AdminError(this.message);
}