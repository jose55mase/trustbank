abstract class CreditsEvent {}

class LoadCreditApplications extends CreditsEvent {}

class SubmitCreditApplication extends CreditsEvent {
  final String creditType;
  final double amount;
  final int termMonths;
  final double interestRate;
  final double monthlyPayment;

  SubmitCreditApplication({
    required this.creditType,
    required this.amount,
    required this.termMonths,
    required this.interestRate,
    required this.monthlyPayment,
  });
}

class CheckApplicationStatus extends CreditsEvent {
  final int applicationId;

  CheckApplicationStatus({required this.applicationId});
}