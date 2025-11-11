import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/request_model.dart';
import '../../../services/api_service.dart';
import '../../notifications/bloc/notifications_bloc.dart';

part 'admin_event.dart';
part 'admin_state.dart';

class AdminBloc extends Bloc<AdminEvent, AdminState> {
  static final List<AdminRequest> _mockRequests = [
    AdminRequest(
      id: '1',
      type: RequestType.sendMoney,
      status: RequestStatus.pending,
      userId: 'user1',
      userName: 'Juan Pérez',
      amount: 150.00,
      details: 'Envío a María García',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    AdminRequest(
      id: '2',
      type: RequestType.recharge,
      status: RequestStatus.pending,
      userId: 'user2',
      userName: 'Ana López',
      amount: 500.00,
      details: 'Recarga con tarjeta de crédito',
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    AdminRequest(
      id: '3',
      type: RequestType.credit,
      status: RequestStatus.approved,
      userId: 'user3',
      userName: 'Carlos Ruiz',
      amount: 10000.00,
      details: 'Crédito personal - 24 meses',
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      processedAt: DateTime.now().subtract(const Duration(hours: 12)),
      adminNotes: 'Documentos verificados correctamente',
    ),
  ];

  AdminBloc() : super(AdminInitial()) {
    on<LoadRequests>(_onLoadRequests);
    on<ProcessRequest>(_onProcessRequest);
    on<FilterRequests>(_onFilterRequests);
  }

  void _onLoadRequests(LoadRequests event, Emitter<AdminState> emit) async {
    try {
      final response = await ApiService.getAllAdminRequests();
      final requests = response.map((data) => AdminRequest(
        id: data['id'].toString(),
        type: _mapRequestType(data['requestType']),
        status: _mapRequestStatus(data['status']),
        userId: data['userId'].toString(),
        userName: 'Usuario ${data['userId']}', // En producción obtener nombre real
        amount: (data['amount'] ?? 0.0).toDouble(),
        details: data['details'] ?? '',
        createdAt: DateTime.parse(data['createdAt']),
        processedAt: data['processedAt'] != null ? DateTime.parse(data['processedAt']) : null,
        adminNotes: data['adminNotes'],
      )).toList();
      
      emit(AdminLoaded(requests: requests));
    } catch (e) {
      emit(AdminLoaded(requests: _mockRequests)); // Fallback a datos mock
    }
  }

  void _onProcessRequest(ProcessRequest event, Emitter<AdminState> emit) async {
    try {
      await ApiService.processAdminRequest(
        int.parse(event.requestId),
        event.status.name.toUpperCase(),
        event.notes,
      );
      
      // Si es una recarga aprobada, actualizar saldo del usuario
      if (event.status == RequestStatus.approved) {
        final currentState = state;
        if (currentState is AdminLoaded) {
          final request = currentState.requests.firstWhere((r) => r.id == event.requestId);
          if (request.type == RequestType.recharge) {
            await _updateUserBalance(int.parse(request.userId), request.amount);
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
      // Fallback a lógica local
      final index = _mockRequests.indexWhere((r) => r.id == event.requestId);
      if (index != -1) {
        _mockRequests[index] = _mockRequests[index].copyWith(
          status: event.status,
          processedAt: DateTime.now(),
          adminNotes: event.notes,
        );
        emit(AdminLoaded(requests: _mockRequests));
      }
    }
  }
  
  Future<void> _updateUserBalance(int userId, double amount) async {
    try {
      // Actualizar saldo del usuario
      await ApiService.updateUserBalance(userId, amount);
      
      // Crear transacción de recarga
      await ApiService.createTransaction({
        'userId': userId,
        'type': 'INCOME',
        'amount': amount,
        'description': 'Recarga de saldo aprobada',
        'date': DateTime.now().toIso8601String(),
      });
      
      print('Balance updated for user $userId with amount $amount');
    } catch (e) {
      print('Error updating balance: $e');
    }
  }

  void _onFilterRequests(FilterRequests event, Emitter<AdminState> emit) {
    List<AdminRequest> filtered = _mockRequests;
    
    if (event.type != null) {
      filtered = filtered.where((r) => r.type == event.type).toList();
    }
    
    if (event.status != null) {
      filtered = filtered.where((r) => r.status == event.status).toList();
    }
    
    emit(AdminLoaded(requests: filtered));
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