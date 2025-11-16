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
  
  // Client information
  final String senderName;
  final String senderAccount;
  final String senderEmail;
  final String senderPhone;
  final String senderAddress;
  final String transactionType;
  final String bankName;
  final String authorizationCode;

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
    required this.senderName,
    required this.senderAccount,
    required this.senderEmail,
    required this.senderPhone,
    required this.senderAddress,
    required this.transactionType,
    required this.bankName,
    required this.authorizationCode,
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
        senderName,
        senderAccount,
        senderEmail,
        senderPhone,
        senderAddress,
        transactionType,
        bankName,
        authorizationCode,
      ];
}