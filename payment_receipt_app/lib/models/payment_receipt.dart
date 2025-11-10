import 'package:equatable/equatable.dart';

class PaymentReceipt extends Equatable {
  final String id;
  final String recipientName;
  final String recipientAccount;
  final double amount;
  final String currency;
  final DateTime date;
  final String concept;
  final String reference;
  final String status;

  const PaymentReceipt({
    required this.id,
    required this.recipientName,
    required this.recipientAccount,
    required this.amount,
    required this.currency,
    required this.date,
    required this.concept,
    required this.reference,
    required this.status,
  });

  @override
  List<Object> get props => [
        id,
        recipientName,
        recipientAccount,
        amount,
        currency,
        date,
        concept,
        reference,
        status,
      ];
}