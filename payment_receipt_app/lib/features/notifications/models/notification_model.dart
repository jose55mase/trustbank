class NotificationModel {
  final String id;
  final String title;
  final String message;
  final DateTime date;
  final NotificationType type;
  final bool isRead;
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? additionalInfo;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.date,
    required this.type,
    this.isRead = false,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.additionalInfo,
  });

  Map<String, dynamic> toJson() => {
    'title': title,
    'message': message,
    'type': type.name,
    'isRead': isRead,
    'userName': userName,
    'userEmail': userEmail,
    'userPhone': userPhone,
    'additionalInfo': additionalInfo,
  };

  factory NotificationModel.fromJson(Map<String, dynamic> json) => NotificationModel(
    id: json['id'].toString(),
    title: json['title'],
    message: json['message'],
    date: DateTime.parse(json['createdAt']),
    type: _mapNotificationType(json['type']),
    isRead: json['isRead'] ?? false,
    userName: json['userName'],
    userEmail: json['userEmail'],
    userPhone: json['userPhone'],
    additionalInfo: json['additionalInfo'],
  );

  static NotificationType _mapNotificationType(String type) {
    switch (type) {
      case 'creditApproved': return NotificationType.creditApproved;
      case 'creditRejected': return NotificationType.creditRejected;
      case 'creditPending': return NotificationType.creditPending;
      case 'sendMoney': return NotificationType.sendMoney;
      case 'recharge': return NotificationType.recharge;
      default: return NotificationType.general;
    }
  }
}

enum NotificationType {
  creditApproved,
  creditRejected,
  creditPending,
  sendMoney,
  recharge,
  general,
}