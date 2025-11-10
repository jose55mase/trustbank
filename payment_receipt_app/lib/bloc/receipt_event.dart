part of 'receipt_bloc.dart';

abstract class ReceiptEvent extends Equatable {
  const ReceiptEvent();

  @override
  List<Object> get props => [];
}

class LoadReceipts extends ReceiptEvent {}

class GeneratePdf extends ReceiptEvent {
  final PaymentReceipt receipt;

  const GeneratePdf(this.receipt);

  @override
  List<Object> get props => [receipt];
}