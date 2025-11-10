part of 'account_bloc.dart';

abstract class AccountEvent {}

class LoadAccount extends AccountEvent {}

class UploadDocument extends AccountEvent {
  final DocumentType type;
  final String fileName;

  UploadDocument({required this.type, required this.fileName});
}