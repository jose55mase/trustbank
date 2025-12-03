part of 'account_bloc.dart';

abstract class AccountEvent {}

class LoadAccount extends AccountEvent {}

class UploadDocument extends AccountEvent {
  final String type;
  final String fileName;

  UploadDocument({required this.type, required this.fileName});
}