part of 'notifications_bloc.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object> get props => [];
}

class LoadNotifications extends NotificationsEvent {}

class AddCreditNotification extends NotificationsEvent {
  final String creditType;
  final double amount;

  const AddCreditNotification({
    required this.creditType,
    required this.amount,
  });

  @override
  List<Object> get props => [creditType, amount];
}

class AddSendMoneyNotification extends NotificationsEvent {
  final String recipient;
  final double amount;

  const AddSendMoneyNotification({
    required this.recipient,
    required this.amount,
  });

  @override
  List<Object> get props => [recipient, amount];
}

class AddRechargeNotification extends NotificationsEvent {
  final double amount;
  final String method;

  const AddRechargeNotification({
    required this.amount,
    required this.method,
  });

  @override
  List<Object> get props => [amount, method];
}

class MarkAsRead extends NotificationsEvent {
  final String notificationId;

  const MarkAsRead(this.notificationId);

  @override
  List<Object> get props => [notificationId];
}