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
      
      // El backend ya actualiza el saldo automáticamente al aprobar
      // No necesitamos duplicar la lógica aquí
      
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