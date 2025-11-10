part of 'admin_bloc.dart';

abstract class AdminEvent {}

class LoadRequests extends AdminEvent {}

class ProcessRequest extends AdminEvent {
  final String requestId;
  final RequestStatus status;
  final String? notes;

  ProcessRequest({
    required this.requestId,
    required this.status,
    this.notes,
  });
}

class FilterRequests extends AdminEvent {
  final RequestType? type;
  final RequestStatus? status;

  FilterRequests({this.type, this.status});
}