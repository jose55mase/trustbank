import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/request_model.dart';
import '../../../services/api_service.dart';
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
      emit(AdminError(e.toString()));
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
      
      // Forzar actualización de datos del usuario en SharedPreferences
      await _refreshUserData(userId);
      
    } catch (e) {
      print('Error updating balance: $e');
    }
  }
  
  Future<void> _refreshUserData(int userId) async {
    try {
      // Obtener usuario actualizado por ID
      final users = await ApiService.getAllAdminRequests(); // Temporal, necesitamos endpoint getUserById
      
      // Por ahora, simplemente esperamos que el usuario refresque manualmente
      print('User data should be refreshed for user $userId');
    } catch (e) {
      print('Error refreshing user data: $e');
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