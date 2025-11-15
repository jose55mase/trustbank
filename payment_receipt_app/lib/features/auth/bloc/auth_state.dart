part of 'auth_bloc.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;

  const AuthAuthenticated({required this.user});

  @override
  List<Object> get props => [user];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object> get props => [message];
}

class AccountSuspended extends AuthState {
  final String message;

  const AccountSuspended(this.message);

  @override
  List<Object> get props => [message];
}

class User extends Equatable {
  final String id;
  final String email;
  final String name;
  final String accountStatus;
  final String role;

  const User({
    required this.id,
    required this.email,
    required this.name,
    this.accountStatus = 'active',
    this.role = 'USER',
  });

  @override
  List<Object> get props => [id, email, name, accountStatus, role];
}