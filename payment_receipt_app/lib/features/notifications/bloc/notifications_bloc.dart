import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/notification_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';
import '../../../utils/currency_formatter.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static final List<NotificationModel> _notifications = <NotificationModel>[];

  NotificationsBloc() : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<LoadUserRequests>(_onLoadUserRequests);
    on<AddCreditNotification>(_onAddCreditNotification);
    on<AddSendMoneyNotification>(_onAddSendMoneyNotification);
    on<AddRechargeNotification>(_onAddRechargeNotification);
    on<MarkAsRead>(_onMarkAsRead);
  }

  void _onLoadNotifications(LoadNotifications event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      
      _notifications.clear();
      
      try {
        final response = await ApiService.getUserNotifications(userId);
        if (response.isNotEmpty) {
          final notifications = response.map<NotificationModel>((data) => NotificationModel(
            id: data['id'].toString(),
            title: data['title'],
            message: data['message'],
            date: DateTime.parse(data['createdAt']),
            type: _mapNotificationType(data['type']),
            isRead: data['isRead'] ?? false,
          )).toList();
          
          notifications.sort((a, b) => b.date.compareTo(a.date));
          _notifications.addAll(notifications);
        }
      } catch (e) {
        // Si no hay backend, agregar notificaciones de ejemplo
        _addSampleNotifications();
      }
      
      // También cargar solicitudes del usuario
      add(LoadUserRequests());
      
      emit(NotificationsLoaded(_notifications));
    } catch (e) {
      _addSampleNotifications();
      emit(NotificationsLoaded(_notifications));
    }
  }
  
  void _addSampleNotifications() {
    final sampleNotifications = [
      NotificationModel(
        id: '1',
        title: 'Bienvenido a TrustBank 🎉',
        message: 'Gracias por unirte a nuestra familia financiera. Explora todos nuestros servicios.',
        date: DateTime.now().subtract(const Duration(hours: 1)),
        type: NotificationType.general,
        isRead: false,
      ),
      NotificationModel(
        id: '2',
        title: 'Recarga Exitosa 💳',
        message: 'Has recargado ${CurrencyFormatter.format(100.0)} exitosamente.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.recharge,
        isRead: true,
      ),
      NotificationModel(
        id: '3',
        title: 'Crédito Disponible 💰',
        message: 'Tienes un crédito pre-aprobado de ${CurrencyFormatter.format(5000.0)}. ¡Solicítalo ahora!',
        date: DateTime.now().subtract(const Duration(days: 1)),
        type: NotificationType.creditApproved,
        isRead: true,
      ),
    ];
    
    _notifications.addAll(sampleNotifications);
  }
  
  void _onLoadUserRequests(LoadUserRequests event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId();
      if (userId == null) return;
      
      final requests = await ApiService.getAllAdminRequests();
      final userRequests = requests.where((r) => r['userId'] == userId).toList();
      
      for (var request in userRequests) {
        final status = request['status'];
        final type = request['requestType'];
        final amount = request['amount']?.toString() ?? '0';
        
        String title = '';
        String message = '';
        NotificationType notifType = NotificationType.general;
        
        if (type == 'RECHARGE' || type == 'BALANCE_RECHARGE') {
          if (status == 'PENDING') {
            title = 'Recarga Pendiente ⏳';
            message = 'Tu solicitud de recarga por ${CurrencyFormatter.format(double.tryParse(amount) ?? 0.0)} está siendo procesada.';
            notifType = NotificationType.recharge;
          } else if (status == 'APPROVED') {
            title = 'Recarga Aprobada ✅';
            message = 'Tu recarga por ${CurrencyFormatter.format(double.tryParse(amount) ?? 0.0)} ha sido aprobada y tu saldo actualizado.';
            notifType = NotificationType.recharge;
          } else if (status == 'REJECTED') {
            title = 'Recarga Rechazada ❌';
            message = 'Tu solicitud de recarga por ${CurrencyFormatter.format(double.tryParse(amount) ?? 0.0)} ha sido rechazada.';
            notifType = NotificationType.recharge;
          }
        }
        
        if (title.isNotEmpty) {
          final notification = NotificationModel(
            id: 'req_${request['id']}',
            title: title,
            message: message,
            date: DateTime.parse(request['createdAt']),
            type: notifType,
            isRead: status != 'PENDING',
          );
          
          // Evitar duplicados
          final exists = _notifications.any((n) => n.id == notification.id);
          if (!exists) {
            _notifications.add(notification);
          }
        }
      }
      
      // Ordenar todas las notificaciones por fecha descendente
      _notifications.sort((a, b) => b.date.compareTo(a.date));
      
      emit(NotificationsLoaded(_notifications));
    } catch (e) {
      // Error silencioso
    }
  }

  void _onAddCreditNotification(AddCreditNotification event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final response = await ApiService.createNotification({
        'userId': userId,
        'title': 'Solicitud Enviada ✉️',
        'message': 'Tu solicitud de ${event.creditType} por ${CurrencyFormatter.format(event.amount)} ha sido enviada y está en proceso de validación.',
        'type': 'credit',
      });
      
      if (response['status'] == 201) {
        add(LoadNotifications());
      } else {
        throw Exception('Error al crear notificación');
      }
    } catch (e) {
      // Error al crear notificación en backend
      print('Error creating notification: $e');
    }
  }

  void _onAddSendMoneyNotification(AddSendMoneyNotification event, Emitter<NotificationsState> emit) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Envío Exitoso 💸',
      message: 'Has enviado ${CurrencyFormatter.format(event.amount)} a ${event.recipient} exitosamente.',
      date: DateTime.now(),
      type: NotificationType.sendMoney,
    );
    
    _notifications.insert(0, notification);
    emit(NotificationsLoaded(_notifications));
  }

  void _onAddRechargeNotification(AddRechargeNotification event, Emitter<NotificationsState> emit) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Recarga Exitosa 💳',
      message: 'Has recargado ${CurrencyFormatter.format(event.amount)} usando ${event.method}.',
      date: DateTime.now(),
      type: NotificationType.recharge,
    );
    
    _notifications.insert(0, notification);
    emit(NotificationsLoaded(_notifications));
  }

  void _onMarkAsRead(MarkAsRead event, Emitter<NotificationsState> emit) {
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      _notifications[index] = NotificationModel(
        id: _notifications[index].id,
        title: _notifications[index].title,
        message: _notifications[index].message,
        date: _notifications[index].date,
        type: _notifications[index].type,
        isRead: true,
      );
    }
    emit(NotificationsLoaded(_notifications));
  }

  static int get unreadCount => _notifications.where((n) => !n.isRead).length;

  NotificationType _mapNotificationType(String type) {
    switch (type) {
      case 'credit':
        return NotificationType.creditPending;
      case 'send_money':
        return NotificationType.sendMoney;
      case 'recharge':
        return NotificationType.recharge;
      default:
        return NotificationType.general;
    }
  }
}