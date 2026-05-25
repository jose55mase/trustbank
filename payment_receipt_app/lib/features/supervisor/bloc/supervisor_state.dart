part of 'supervisor_bloc.dart';

abstract class SupervisorState {}

class SupervisorInitial extends SupervisorState {}

class SupervisorLoading extends SupervisorState {}

class SupervisorLeadsLoaded extends SupervisorState {
  final List<LeadModel> leads;
  final int totalPages;
  final int currentPage;
  final int totalItems;
  final bool hasNext;
  final bool hasPrevious;

  SupervisorLeadsLoaded({
    required this.leads,
    required this.totalPages,
    required this.currentPage,
    required this.totalItems,
    this.hasNext = false,
    this.hasPrevious = false,
  });
}

class SupervisorLeadDetail extends SupervisorState {
  final LeadModel lead;

  SupervisorLeadDetail({required this.lead});
}

class SupervisorLeadUpdated extends SupervisorState {
  final LeadModel lead;

  SupervisorLeadUpdated({required this.lead});
}

class SupervisorError extends SupervisorState {
  final String message;

  SupervisorError({required this.message});
}
