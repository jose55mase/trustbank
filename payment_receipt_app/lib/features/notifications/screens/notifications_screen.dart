import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../design_system/colors/tb_colors.dart';
import '../../../design_system/typography/tb_typography.dart';
import '../../../design_system/spacing/tb_spacing.dart';
import '../bloc/notifications_bloc.dart';
import '../models/notification_model.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => NotificationsBloc()..add(LoadNotifications()),
      child: Scaffold(
        backgroundColor: TBColors.background,
        appBar: AppBar(
          title: Text('Notificaciones', style: TBTypography.headlineMedium),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: BlocBuilder<NotificationsBloc, NotificationsState>(
          builder: (context, state) {
            if (state is NotificationsLoaded) {
              if (state.notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: TBColors.grey500,
                      ),
                      const SizedBox(height: TBSpacing.md),
                      Text(
                        'No tienes notificaciones',
                        style: TBTypography.titleLarge.copyWith(
                          color: TBColors.grey600,
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(TBSpacing.screenPadding),
                itemCount: state.notifications.length,
                itemBuilder: (context, index) {
                  final notification = state.notifications[index];
                  return _buildNotificationItem(context, notification);
                },
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, NotificationModel notification) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.md),
      decoration: BoxDecoration(
        color: notification.isRead ? TBColors.surface : TBColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(
          color: notification.isRead ? TBColors.grey300.withOpacity(0.5) : TBColors.primary.withOpacity(0.2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(TBSpacing.md),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: _getNotificationColor(notification.type).withOpacity(0.1),
            borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
          ),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: _getNotificationColor(notification.type),
            size: 24,
          ),
        ),
        title: Text(
          notification.title,
          style: TBTypography.titleLarge.copyWith(
            fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.w700,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: TBSpacing.xs),
            Text(
              notification.message,
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
            ),
            const SizedBox(height: TBSpacing.xs),
            Text(
              DateFormat('dd/MM/yyyy HH:mm').format(notification.date),
              style: TBTypography.labelMedium.copyWith(
                color: TBColors.grey500,
              ),
            ),
          ],
        ),
        trailing: !notification.isRead
            ? Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
              )
            : null,
        onTap: () {
          if (!notification.isRead) {
            context.read<NotificationsBloc>().add(MarkAsRead(notification.id));
          }
        },
      ),
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.creditApproved:
        return TBColors.success;
      case NotificationType.creditRejected:
        return TBColors.error;
      case NotificationType.creditPending:
        return Colors.orange;
      case NotificationType.sendMoney:
        return Colors.blue;
      case NotificationType.recharge:
        return Colors.green;
      case NotificationType.general:
        return TBColors.primary;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.creditApproved:
        return Icons.check_circle;
      case NotificationType.creditRejected:
        return Icons.cancel;
      case NotificationType.creditPending:
        return Icons.hourglass_empty;
      case NotificationType.sendMoney:
        return Icons.send;
      case NotificationType.recharge:
        return Icons.add_circle;
      case NotificationType.general:
        return Icons.info;
    }
  }
}