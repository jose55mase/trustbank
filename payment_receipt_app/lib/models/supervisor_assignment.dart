import 'package:equatable/equatable.dart';

class SupervisorAssignment extends Equatable {
  final int id;
  final int userId;
  final String userName;
  final int assignmentTypeId;
  final String assignmentTypeName;
  final DateTime assignedAt;

  const SupervisorAssignment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.assignmentTypeId,
    required this.assignmentTypeName,
    required this.assignedAt,
  });

  factory SupervisorAssignment.fromJson(Map<String, dynamic> json) {
    return SupervisorAssignment(
      id: json['id'] as int,
      userId: json['userId'] as int,
      userName: json['userName'] as String? ?? '',
      assignmentTypeId: json['assignmentTypeId'] as int,
      assignmentTypeName: json['assignmentTypeName'] as String? ?? '',
      assignedAt: DateTime.parse(json['assignedAt'] as String),
    );
  }

  @override
  List<Object> get props => [
        id,
        userId,
        userName,
        assignmentTypeId,
        assignmentTypeName,
        assignedAt,
      ];
}
