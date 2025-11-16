import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/payment_receipt.dart';
import '../services/pdf_service.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

part 'receipt_event.dart';
part 'receipt_state.dart';

class ReceiptBloc extends Bloc<ReceiptEvent, ReceiptState> {
  ReceiptBloc() : super(const ReceiptInitial()) {
    on<LoadReceipts>(_onLoadReceipts);
    on<GeneratePdf>(_onGeneratePdf);
  }

  Future<void> _onLoadReceipts(
    LoadReceipts event,
    Emitter<ReceiptState> emit,
  ) async {
    emit(ReceiptLoading());
    
    try {
      final user = await AuthService.getCurrentUser();
      if (user == null) {
        emit(ReceiptError('Usuario no encontrado'));
        return;
      }
      
      final userId = user['id'];
      final receipts = <PaymentReceipt>[];
      
      // Cargar transacciones del backend
      try {
        final backendTransactions = await ApiService.getUserTransactions(userId);
        for (final transaction in backendTransactions) {
          receipts.add(await _mapTransactionToReceipt(transaction));
        }
      } catch (e) {
        // Error loading backend transactions logged
      }
      
      // Cargar transacciones locales
      final prefs = await SharedPreferences.getInstance();
      final transactionsKey = 'user_transactions_$userId';
      final localTransactionsString = prefs.getString(transactionsKey) ?? '[]';
      final localTransactions = List<dynamic>.from(json.decode(localTransactionsString));
      
      for (final transaction in localTransactions) {
        receipts.add(await _mapTransactionToReceipt(transaction));
      }
      
      // Ordenar por fecha descendente
      receipts.sort((a, b) => b.date.compareTo(a.date));
      
      emit(ReceiptLoaded(receipts));
    } catch (e) {
      emit(ReceiptError(e.toString()));
    }
  }
  
  Future<PaymentReceipt> _mapTransactionToReceipt(Map<String, dynamic> transaction) async {
    final isIncome = transaction['type'] == 'INCOME';
    final user = await AuthService.getCurrentUser();
    
    return PaymentReceipt(
      id: transaction['id'].toString(),
      recipientName: transaction['toUser'] ?? (isIncome ? 'Mi Cuenta' : 'Destinatario'),
      recipientAccount: isIncome ? '****1234' : '****5678',
      amount: (transaction['amount'] ?? 0.0).toDouble(),
      currency: 'USD',
      date: DateTime.parse(transaction['date'] ?? DateTime.now().toIso8601String()),
      concept: transaction['description'] ?? 'Transacción',
      reference: 'TB${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      status: 'Completado',
      
      // Client information
      senderName: user?['fistName'] ?? user?['name'] ?? 'Usuario TrustBank',
      senderAccount: '****1234',
      senderEmail: user?['email'] ?? 'usuario@trustbank.com',
      senderPhone: user?['phone'] ?? '+1 (555) 123-4567',
      senderAddress: user?['address'] ?? 'Ciudad, País',
      transactionType: isIncome ? 'Depósito' : 'Transferencia',
      bankName: 'TrustBank',
      authorizationCode: 'AUTH${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
    );
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