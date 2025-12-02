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
      
      if (response['status'] != 200) {
        emit(AdminError('Error al cargar solicitudes'));
        return;
      }
      
      final requestsData = (response['data'] as List).cast<Map<String, dynamic>>();
      final requests = requestsData.map((data) => AdminRequest(
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
          // Para SEND_MONEY restar dinero, para otros tipos sumar
          final amount = request.type == RequestType.sendMoney ? -request.amount : request.amount;
          await _updateUserBalance(int.parse(request.userId), amount, request.type);
        }
      }
      
      // Crear notificación específica para créditos aprobados
      if (event.status == RequestStatus.approved) {
        final currentState = state;
        if (currentState is AdminLoaded) {
          final request = currentState.requests.firstWhere((r) => r.id == event.requestId);
          if (request.type == RequestType.credit) {
            try {
              await ApiService.createNotification({
                'userId': int.parse(request.userId),
                'title': '🎉 Crédito Aprobado',
                'message': 'Tu crédito por ${request.amount.toStringAsFixed(2)} USD ha sido aprobado y el dinero ya está disponible en tu cuenta.',
                'type': 'creditApproved',
                'additionalInfo': 'Monto desembolsado: \$${request.amount.toStringAsFixed(2)} USD',
              });
            } catch (e) {
              // Error silencioso al crear notificación
            }
          }
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
  
  Future<void> _updateUserBalance(int userId, double amount, RequestType requestType) async {
    try {
      print('Starting balance update for user $userId with amount $amount for ${requestType.name}');
      
      // 1. Actualizar saldo en base de datos
      await _updateBackendBalance(userId, amount);
      
      // 2. Actualizar localmente para UI inmediata
      await _updateLocalBalance(userId, amount, requestType);
      
      // 3. Crear transacción en base de datos
      try {
        String transactionType;
        String description;
        
        switch (requestType) {
          case RequestType.sendMoney:
            transactionType = 'EXPENSE';
            description = 'Envío de dinero aprobado por administrador';
            break;
          case RequestType.recharge:
            transactionType = 'INCOME';
            description = 'Recarga de saldo aprobada por administrador';
            break;
          case RequestType.credit:
            transactionType = 'INCOME';
            description = 'Crédito aprobado y desembolsado';
            break;
        }
        
        final transactionData = {
          'userId': userId,
          'type': transactionType,
          'amount': amount.abs(),
          'description': description,
          'date': DateTime.now().toIso8601String(),
          'category': requestType == RequestType.credit ? 'CREDIT_DISBURSEMENT' : 'ADMIN_APPROVAL',
        };
        
        print('Creating transaction: $transactionData');
        await ApiService.createTransaction(transactionData);
        print('Transaction created successfully for user $userId');
      } catch (e) {
        print('Error creating transaction for user $userId: $e');
      }
      
      print('Balance update process completed for user $userId');
      
    } catch (e) {
      print('Error updating balance for user $userId: $e');
    }
  }
  
  Future<void> _updateBackendBalance(int userId, double amount) async {
    try {
      // Obtener datos del usuario específico desde el backend
      final userResponse = await ApiService.getUserById(userId);
      
      if (userResponse['status'] == 200) {
        final userData = userResponse['data'];
        final currentBalance = (userData['moneyclean'] ?? userData['balance'] ?? 0.0).toDouble();
        final newBalance = currentBalance + amount;
        
        // Crear objeto UserEntity completo con saldo actualizado
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
        
        await ApiService.updateUser(userEntity);
        print('Backend balance updated for user $userId: $newBalance');
      }
    } catch (e) {
      print('Error updating backend balance for user $userId: $e');
    }
  }
  

  
  Future<void> _updateLocalBalance(int userId, double amount, RequestType requestType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('user_data');
      
      // Solo actualizar localmente si es el usuario actual
      if (userDataString != null) {
        final userData = json.decode(userDataString);
        if (userData['id'] == userId) {
          // Actualizar saldo del usuario actual
          final currentBalance = (userData['moneyclean'] ?? userData['balance'] ?? 0.0).toDouble();
          userData['moneyclean'] = currentBalance + amount;
          
          await prefs.setString('user_data', json.encode(userData));
          print('Local balance updated for current user $userId: ${userData['moneyclean']}');
          
          // Notificar actualización de saldo globalmente
          BalanceService().updateBalance(userId, userData['moneyclean']);
          
          // Agregar transacción local a movimientos recientes
          await _addLocalTransaction(userId, amount, requestType);
        } else {
          print('Skipping local update - user $userId is not current user');
        }
      }
    } catch (e) {
      print('Error updating local balance: $e');
    }
  }
  
  Future<void> _addLocalTransaction(int userId, double amount, RequestType requestType) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final transactionsKey = 'user_transactions_$userId';
      final transactionsString = prefs.getString(transactionsKey) ?? '[]';
      final transactions = List<Map<String, dynamic>>.from(json.decode(transactionsString));
      
      // Agregar nueva transacción al inicio
      String transactionType;
      String description;
      
      switch (requestType) {
        case RequestType.sendMoney:
          transactionType = 'EXPENSE';
          description = 'Envío de dinero aprobado por administrador';
          break;
        case RequestType.recharge:
          transactionType = 'INCOME';
          description = 'Recarga de saldo aprobada por administrador';
          break;
        case RequestType.credit:
          transactionType = 'INCOME';
          description = 'Crédito aprobado y desembolsado';
          break;
      }
      
      final newTransaction = {
        'id': DateTime.now().millisecondsSinceEpoch,
        'userId': userId,
        'type': transactionType,
        'amount': amount.abs(),
        'description': description,
        'date': DateTime.now().toIso8601String(),
      };
      
      transactions.insert(0, newTransaction);
      
      // Mantener solo las últimas 50 transacciones
      if (transactions.length > 50) {
        transactions.removeRange(50, transactions.length);
      }
      
      await prefs.setString(transactionsKey, json.encode(transactions));
      // Local transaction added successfully
      
    } catch (e) {
      // Error adding local transaction: silently continue
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