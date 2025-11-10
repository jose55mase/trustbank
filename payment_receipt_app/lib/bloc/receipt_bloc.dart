import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/payment_receipt.dart';
import '../services/pdf_service.dart';

part 'receipt_event.dart';
part 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  ReceiptBloc() : super(ReceiptInitial()) {
    on<LoadReceipts>(_onLoadReceipts);
    on<GeneratePdf>(_onGeneratePdf);
  }

  Future<void> _onLoadReceipts(
    LoadReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(ReceiptLoading());
    
    try {
      await Future.delayed(const Duration(seconds: 1));
      
      final receipts = [
        PaymentReceipt(
          id: 'TXN001',
          recipientName: 'Juan Pérez',
          recipientAccount: '1234567890',
          amount: 150.00,
          currency: 'USD',
          date: DateTime.now().subtract(const Duration(days: 1)),
          concept: 'Pago de servicios',
          reference: 'REF001',
          status: 'Completado',
        ),
        PaymentReceipt(
          id: 'TXN002',
          recipientName: 'María García',
          recipientAccount: '0987654321',
          amount: 75.00,
          currency: 'USD',
          date: DateTime.now().subtract(const Duration(days: 2)),
          concept: 'Transferencia personal',
          reference: 'REF002',
          status: 'Completado',
        ),
      ];
      
      emit(ReceiptLoaded(receipts));
    } catch (e) {
      emit(ReceiptError(e.toString()));
    }
  }

  Future<void> _onGeneratePdf(
    GeneratePdf event,
    Emitter<ReceiptState> emit,
  ) async {
    try {
      await PdfService.generateAndDownloadReceipt(event.receipt);
    } catch (e) {
      emit(ReceiptError('Error generando PDF: ${e.toString()}'));
    }
  }
}