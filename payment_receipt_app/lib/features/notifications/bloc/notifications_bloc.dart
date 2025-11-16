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
      
      // Siempre agregar notificaciones de ejemplo primero
      _addSampleNotifications();
      
      try {
        final response = await ApiService.getUserNotifications(userId);
        if (response.isNotEmpty) {
          final notifications = response.map<NotificationModel>((data) => 
            NotificationModel.fromJson(data)
          ).toList();
          
          notifications.sort((a, b) => b.date.compareTo(a.date));
          _notifications.addAll(notifications);
        }
      } catch (e) {
        // Backend no disponible, agregar notificaciones de transacciones de ejemplo
        _addTransactionNotifications();
      }
      
      // También cargar solicitudes del usuario
      try {
        await _loadUserRequestsDirectly();
      } catch (e) {
        // Error silencioso para requests - agregar notificaciones de ejemplo si no hay backend
        if (_notifications.length <= 1) {
          _addTransactionNotifications();
        }
      }
      
      // Ordenar todas las notificaciones por fecha
      _notifications.sort((a, b) => b.date.compareTo(a.date));
      
      emit(NotificationsLoaded(_notifications));
    } catch (e) {
      // En caso de error total, asegurar que hay notificaciones de ejemplo
      _notifications.clear();
      _addSampleNotifications();
      emit(NotificationsLoaded(_notifications));
    }
  }
  
  void _addSampleNotifications() {
    const userName = 'Usuario';
    const userEmail = 'usuario@trustbank.com';
    const userPhone = '+1 234 567 8900';
    
    final sampleNotifications = [
      NotificationModel(
        id: 'welcome_1',
        title: 'Bienvenido a TrustBank 🎉',
        message: 'Hola $userName, gracias por unirte a nuestra familia financiera. Explora todos nuestros servicios.',
        date: DateTime.now().subtract(const Duration(minutes: 30)),
        type: NotificationType.general,
        isRead: false,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Cuenta creada exitosamente',
      ),
    ];
    
    _notifications.addAll(sampleNotifications);
  }
  
  void _addTransactionNotifications() {
    const userName = 'Usuario';
    const userEmail = 'usuario@trustbank.com';
    const userPhone = '+1 234 567 8900';
    
    final transactionNotifications = [
      NotificationModel(
        id: 'trans_1',
        title: 'Recarga Aprobada ✅',
        message: 'Hola $userName, tu recarga de ${CurrencyFormatter.format(500.0)} ha sido aprobada y tu saldo actualizado.',
        date: DateTime.now().subtract(const Duration(hours: 2)),
        type: NotificationType.recharge,
        isRead: false,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Método: Tarjeta de crédito **** 1234',
      ),
      NotificationModel(
        id: 'trans_2',
        title: 'Envío Completado 💸',
        message: 'Hola $userName, tu envío de ${CurrencyFormatter.format(150.0)} a Juan Pérez ha sido completado exitosamente.',
        date: DateTime.now().subtract(const Duration(hours: 5)),
        type: NotificationType.sendMoney,
        isRead: true,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Destinatario: Juan Pérez - Banco Nacional',
      ),
    ];
    
    _notifications.addAll(transactionNotifications);
  }
  
  void _onLoadUserRequests(LoadUserRequests event, Emitter<NotificationsState> emit) async {
    await _loadUserRequestsDirectly();
    emit(NotificationsLoaded(_notifications));
  }
  
  Future<void> _loadUserRequestsDirectly() async {
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
        } else if (type == 'SEND_MONEY') {
          if (status == 'PENDING') {
            title = 'Envío Pendiente ⏳';
            message = 'Tu envío de ${CurrencyFormatter.format(double.tryParse(amount) ?? 0.0)} está siendo procesado.';
            notifType = NotificationType.sendMoney;
          } else if (status == 'APPROVED') {
            title = 'Envío Completado ✅';
            message = 'Tu envío de ${CurrencyFormatter.format(double.tryParse(amount) ?? 0.0)} ha sido completado exitosamente.';
            notifType = NotificationType.sendMoney;
          }
        }
        
        if (title.isNotEmpty) {
          final currentUser = await AuthService.getCurrentUser();
          final userName = currentUser?['name'] ?? 'Usuario';
          final userEmail = currentUser?['email'] ?? 'usuario@trustbank.com';
          final userPhone = currentUser?['phone'] ?? '+1 234 567 8900';
          
          final notification = NotificationModel(
            id: 'req_${request['id']}',
            title: title,
            message: message,
            date: DateTime.parse(request['createdAt']),
            type: notifType,
            isRead: status != 'PENDING',
            userName: userName,
            userEmail: userEmail,
            userPhone: userPhone,
            additionalInfo: request['details'] ?? 'Solicitud procesada',
          );
          
          // Evitar duplicados
          final exists = _notifications.any((n) => n.id == notification.id);
          if (!exists) {
            _notifications.add(notification);
          }
        }
      }
    } catch (e) {
      // Error silencioso - no afecta las notificaciones principales
    }
  }

  void _onAddCreditNotification(AddCreditNotification event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      
      final response = await ApiService.createNotification({
        'userId': userId,
        'title': 'Solicitud Enviada ✉️',
        'message': 'Hola $userName, tu solicitud de ${event.creditType} por ${CurrencyFormatter.format(event.amount)} ha sido enviada y está en proceso de validación.',
        'type': 'creditPending',
        'additionalInfo': 'Tipo de crédito: ${event.creditType} - Monto: ${CurrencyFormatter.format(event.amount)}',
      });
      
      if (response['status'] == 201 || response.containsKey('id')) {
        add(LoadNotifications());
      } else {
        throw Exception('Error al crear notificación');
      }
    } catch (e) {
      // Error al crear notificación en backend - agregar localmente
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      final userEmail = currentUser?['email'] ?? 'usuario@trustbank.com';
      final userPhone = currentUser?['phone'] ?? '+1 234 567 8900';
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Solicitud Enviada ✉️',
        message: 'Hola $userName, tu solicitud de ${event.creditType} por ${CurrencyFormatter.format(event.amount)} ha sido enviada.',
        date: DateTime.now(),
        type: NotificationType.creditPending,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Tipo de crédito: ${event.creditType}',
      );
      
      _notifications.insert(0, notification);
      emit(NotificationsLoaded(_notifications));
      print('Error creating notification: $e');
    }
  }

  void _onAddSendMoneyNotification(AddSendMoneyNotification event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      
      await ApiService.createNotification({
        'userId': userId,
        'title': 'Envío Exitoso 💸',
        'message': 'Hola $userName, has enviado ${CurrencyFormatter.format(event.amount)} a ${event.recipient} exitosamente.',
        'type': 'sendMoney',
        'additionalInfo': 'Destinatario: ${event.recipient} - Monto: ${CurrencyFormatter.format(event.amount)}',
      });
      
      add(LoadNotifications());
    } catch (e) {
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      final userEmail = currentUser?['email'] ?? 'usuario@trustbank.com';
      final userPhone = currentUser?['phone'] ?? '+1 234 567 8900';
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Envío Exitoso 💸',
        message: 'Hola $userName, has enviado ${CurrencyFormatter.format(event.amount)} a ${event.recipient} exitosamente.',
        date: DateTime.now(),
        type: NotificationType.sendMoney,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Destinatario: ${event.recipient}',
      );
      
      _notifications.insert(0, notification);
      emit(NotificationsLoaded(_notifications));
    }
  }

  void _onAddRechargeNotification(AddRechargeNotification event, Emitter<NotificationsState> emit) async {
    try {
      final userId = await AuthService.getCurrentUserId() ?? 1;
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      
      await ApiService.createNotification({
        'userId': userId,
        'title': 'Recarga Exitosa 💳',
        'message': 'Hola $userName, has recargado ${CurrencyFormatter.format(event.amount)} usando ${event.method}.',
        'type': 'recharge',
        'additionalInfo': 'Método de pago: ${event.method} - Monto: ${CurrencyFormatter.format(event.amount)}',
      });
      
      add(LoadNotifications());
    } catch (e) {
      final currentUser = await AuthService.getCurrentUser();
      final userName = currentUser?['name'] ?? 'Usuario';
      final userEmail = currentUser?['email'] ?? 'usuario@trustbank.com';
      final userPhone = currentUser?['phone'] ?? '+1 234 567 8900';
      
      final notification = NotificationModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'Recarga Exitosa 💳',
        message: 'Hola $userName, has recargado ${CurrencyFormatter.format(event.amount)} usando ${event.method}.',
        date: DateTime.now(),
        type: NotificationType.recharge,
        userName: userName,
        userEmail: userEmail,
        userPhone: userPhone,
        additionalInfo: 'Método de pago: ${event.method}',
      );
      
      _notifications.insert(0, notification);
      emit(NotificationsLoaded(_notifications));
    }
  }

  void _onMarkAsRead(MarkAsRead event, Emitter<NotificationsState> emit) {
    final index = _notifications.indexWhere((n) => n.id == event.notificationId);
    if (index != -1) {
      final oldNotification = _notifications[index];
      _notifications[index] = NotificationModel(
        id: oldNotification.id,
        title: oldNotification.title,
        message: oldNotification.message,
        date: oldNotification.date,
        type: oldNotification.type,
        isRead: true,
        userName: oldNotification.userName,
        userEmail: oldNotification.userEmail,
        userPhone: oldNotification.userPhone,
        additionalInfo: oldNotification.additionalInfo,
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