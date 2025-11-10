import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../models/notification_model.dart';
import '../../../services/api_service.dart';
import '../../../services/auth_service.dart';

part 'notifications_event.dart';
part 'notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  static final List<NotificationModel> _notifications = [
    NotificationModel(
      id: '1',
      title: 'Crédito Aprobado ✅',
      message: 'Tu solicitud de Crédito Personal por \$5,000 ha sido aprobada. Revisa los términos y condiciones.',
      date: DateTime.now().subtract(const Duration(hours: 2)),
      type: NotificationType.creditApproved,
    ),
    NotificationModel(
      id: '2',
      title: 'Solicitud en Revisión ⏳',
      message: 'Tu solicitud de Crédito Vehicular está siendo evaluada. Te contactaremos pronto.',
      date: DateTime.now().subtract(const Duration(days: 1)),
      type: NotificationType.creditPending,
    ),
    NotificationModel(
      id: '3',
      title: 'Bienvenido a TrustBank 🎉',
      message: 'Gracias por unirte a nuestra familia financiera. Explora todos nuestros servicios.',
      date: DateTime.now().subtract(const Duration(days: 3)),
      type: NotificationType.general,
      isRead: true,
    ),
  ];

  NotificationsBloc() : super(NotificationsInitial()) {
    on<LoadNotifications>(_onLoadNotifications);
    on<AddCreditNotification>(_onAddCreditNotification);
    on<AddSendMoneyNotification>(_onAddSendMoneyNotification);
    on<AddRechargeNotification>(_onAddRechargeNotification);
    on<MarkAsRead>(_onMarkAsRead);
  }

  void _onLoadNotifications(LoadNotifications event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
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
        
        _notifications.clear();
        _notifications.addAll(notifications);
      }
      emit(NotificationsLoaded(_notifications));
    } catch (e) {
      // Mantener notificaciones locales si falla la conexión
      emit(NotificationsLoaded(_notifications));
    }
  }

  void _onAddCreditNotification(AddCreditNotification event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final response = await ApiService.createNotification({
        'userId': userId,
        'title': 'Solicitud Enviada ✉️',
        'message': 'Tu solicitud de ${event.creditType} por \$${event.amount.toStringAsFixed(2)} ha sido enviada y está en proceso de validación.',
        'type': 'credit',
      });
      
      if (response['status'] == 201) {
        add(LoadNotifications());
      } else {
        throw Exception('Error al crear notificación');
      }
    } catch (e) {
      // Fallback local
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Solicitud Enviada ✉️',
        message: 'Tu solicitud de ${event.creditType} por \$${event.amount.toStringAsFixed(2)} ha sido enviada y está en proceso de validación.',
        date: DateTime.now(),
        type: NotificationType.creditPending,
      );
      _notifications.insert(0, notification);
      emit(NotificationsLoaded(_notifications));
    }
  }

  void _onAddSendMoneyNotification(AddSendMoneyNotification event, Emitter<NotificationsState> emit) {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: 'Envío Exitoso 💸',
      message: 'Has enviado \$${event.amount.toStringAsFixed(2)} a ${event.recipient} exitosamente.',
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
      message: 'Has recargado \$${event.amount.toStringAsFixed(2)} usando ${event.method}.',
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