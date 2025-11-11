import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/request_model.dart';
import '../../../services/api_service.dart';
import '../../../services/balance_service.dart';
import '../../notifications/bloc/notifications_bloc.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {

  AdminBloc() : super(AdminInitial()) {
    on<LoadRequests>(_onLoadRequests);
    on<ProcessRequest>(_onProcessRequest);
    on<FilterRequests>(_onFilterRequests);
  }

  void _onLoadRequests(LoadRequests event, Emitter<AdminState> emit) async {
    try {
      emit(AdminLoading());
      final response = await ApiService.getAllAdminRequests();
      final requests = response.map((data) => AdminRequest(
        id: data['id'].toString(),
        type: _mapRequestType(data['requestType']),
        status: _mapRequestStatus(data['status']),
        userId: data['userId'].toString(),
        userName: 'Usuario ${data['userId']}',
        amount: (data['amount'] ?? 0.0).toDouble(),
        details: data['details'] ?? '',
        createdAt: DateTime.parse(data['createdAt']),
        processedAt: data['processedAt'] != null ? DateTime.parse(data['processedAt']) : null,
        adminNotes: data['adminNotes'],
      )).toList();
      
      // Ordenar por fecha descendente (más recientes primero)
      requests.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      emit(AdminLoaded(requests: requests));
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }

  void _onProcessRequest(ProcessRequest event, Emitter<AdminState> emit) async {
    try {
      await ApiService.processAdminRequest(
        int.parse(event.requestId),
        event.status.name.toUpperCase(),
        event.notes,
      );
      
      // Si es una transacción aprobada, actualizar saldo del usuario
      if (event.status == RequestStatus.approved) {
        final currentState = state;
        if (currentState is AdminLoaded) {
          final request = currentState.requests.firstWhere((r) => r.id == event.requestId);
          // Sumar el monto a la cuenta para cualquier tipo de transacción aprobada
          await _updateUserBalance(int.parse(request.userId), request.amount);
        }
      }
      
      // Recargar solicitudes y actualizar notificaciones
      add(LoadRequests());
      
      // Actualizar notificaciones del usuario
      try {
        final notificationsBloc = NotificationsBloc();
        notificationsBloc.add(LoadNotifications());
      } catch (e) {
        // Error silencioso
      }
    } catch (e) {
      emit(AdminError(e.toString()));
    }
  }
  
  Future<void> _updateUserBalance(int userId, double amount) async {
    try {
      print('Starting balance update for user $userId with amount $amount');
      
      // 1. Actualizar saldo en base de datos
      await _updateBackendBalance(userId, amount);
      
      // 2. Actualizar localmente para UI inmediata
      await _updateLocalBalance(userId, amount);
      
      // 3. Crear transacción en base de datos
      try {
        final transactionResponse = await ApiService.createTransaction({
          'userId': userId,
          'type': 'INCOME',
          'amount': amount,
          'description': 'Transacción aprobada por administrador',
          'date': DateTime.now().toIso8601String(),
        });
        print('Transaction created: $transactionResponse');
      } catch (e) {
        print('Error creating transaction: $e');
      }
      
      print('Balance update process completed for user $userId');
      
    } catch (e) {
      print('Error updating balance: $e');
    }
  }
  
  Future<void> _updateBackendBalance(int userId, double amount) async {
    try {
      // Obtener datos completos del usuario
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['id'] == userId) {
          final currentBalance = (userData['moneyclean'] ?? userData['balance'] ?? 0.0).toDouble();
          final newBalance = currentBalance + amount;
          
          // Crear objeto UserEntity completo
          final userEntity = {
            'id': userData['id'],
            'name': userData['name'],
            'email': userData['email'],
            'password': userData['password'],
            'moneyclean': newBalance,
            'balance': newBalance,
            'phone': userData['phone'],
            'address': userData['address'],
            'documentType': userData['documentType'],
            'documentNumber': userData['documentNumber'],
            'accountStatus': userData['accountStatus'] ?? 'ACTIVE',
            'createdAt': userData['createdAt'],
            'updatedAt': DateTime.now().toIso8601String(),
          };
          
          final response = await ApiService.updateUser(userEntity);
          print('Backend balance updated to: $newBalance');
        }
      }
    } catch (e) {
      print('Error updating backend balance: $e');
      // Continuar con actualización local aunque falle el backend
    }
  }
  
  Future<void> _refreshUserData(int userId) async {
    try {
      print('User data should be refreshed for user $userId');
      // El usuario tendrá que refrescar manualmente o esperar el auto-refresh
    } catch (e) {
      print('Error refreshing user data: $e');
    }
  }
  
  Future<void> _updateLocalBalance(int userId, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['id'] == userId) {
          // Actualizar saldo
          final currentBalance = (userData['moneyclean'] ?? userData['balance'] ?? 0.0).toDouble();
          userData['moneyclean'] = currentBalance + amount;
          
          await prefs.setString('user_data', json.encode(userData));
          print('Local balance updated: ${userData['moneyclean']}');
          
          // Notificar actualización de saldo globalmente
          BalanceService().updateBalance(userId, userData['moneyclean']);
          
          // Agregar transacción local a movimientos recientes
          await _addLocalTransaction(userId, amount);
        }
      }
    } catch (e) {
      print('Error updating local balance: $e');
    }
  }
  
  Future<void> _addLocalTransaction(int userId, double amount) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsKey = 'user_transactions_$userId';
      final transactionsString = prefs.getString(transactionsKey) ?? '[]';
      final transactions = List<Map<String, dynamic>>.from(json.decode(transactionsString));
      
      // Agregar nueva transacción al inicio
      final newTransaction = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
        'type': 'INCOME',
        'amount': amount,
        'description': 'Transacción aprobada por administrador',
        'date': DateTime.now().toIso8601String(),
      };
      
      transactions.insert(0, newTransaction);
      
      // Mantener solo las últimas 50 transacciones
      if (transactions.length > 50) {
        transactions.removeRange(50, transactions.length);
      }
      
      await prefs.setString(transactionsKey, json.encode(transactions));
      print('Local transaction added: +\$${amount.toStringAsFixed(2)}');
      
    } catch (e) {
      print('Error adding local transaction: $e');
    }
  }

  void _onFilterRequests(FilterRequests event, Emitter<AdminState> emit) {
    // Recargar desde backend con filtros
    add(LoadRequests());
  }

  RequestType _mapRequestType(String type) {
    switch (type) {
      case 'SEND_MONEY':
        return RequestType.sendMoney;
      case 'RECHARGE':
      case 'BALANCE_RECHARGE':
        return RequestType.recharge;
      case 'CREDIT':
        return RequestType.credit;
      default:
        return RequestType.sendMoney;
    }
  }

  RequestStatus _mapRequestStatus(String status) {
    switch (status) {
      case 'PENDING':
        return RequestStatus.pending;
      case 'APPROVED':
        return RequestStatus.approved;
      case 'REJECTED':
        return RequestStatus.rejected;
      default:
        return RequestStatus.pending;
    }
  }
}