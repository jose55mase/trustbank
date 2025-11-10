part of 'account_bloc.dart';

abstract class AccountState {}

class AccountInitial extends AccountState {}

class AccountLoading extends AccountState {}

class AccountLoaded extends AccountState {
  final UserAccount account;

  AccountLoaded({required this.account});
}