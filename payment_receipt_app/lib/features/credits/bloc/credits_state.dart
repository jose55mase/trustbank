import '../models/credit_application.dart';

abstract class CreditsState {}

class CreditsInitial extends CreditsState {}

class CreditsLoading extends CreditsState {}

class CreditsSubmitting extends CreditsState {}

class CreditsLoaded extends CreditsState {
  final List<CreditApplication> applications;

  CreditsLoaded({required this.applications});
}

class CreditApplicationSubmitted extends CreditsState {
  final CreditApplication application;

  CreditApplicationSubmitted({required this.application});
}

class CreditStatusUpdated extends CreditsState {
  final CreditApplication application;

  CreditStatusUpdated({required this.application});
}

class CreditsError extends CreditsState {
  final String message;

  CreditsError({required this.message});
}