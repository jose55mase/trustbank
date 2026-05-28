part of 'supervisor_bloc.dart';

abstract class SupervisorEvent {}

/// Carga la lista de leads paginados del supervisor.
class LoadSupervisorLeads extends SupervisorEvent {
  final int page;
  final int size;
  final String? status;

  LoadSupervisorLeads({this.page = 0, this.size = 20, this.status});
}

/// Busca leads dentro de la asignación del supervisor.
class SearchSupervisorLeads extends SupervisorEvent {
  final String term;
  final int page;
  final int size;

  SearchSupervisorLeads({required this.term, this.page = 0, this.size = 20});
}

/// Selecciona un lead para ver su detalle.
class SelectLead extends SupervisorEvent {
  final int leadId;

  SelectLead({required this.leadId});
}

/// Actualiza parcialmente un lead (solo campos modificados).
class UpdateLead extends SupervisorEvent {
  final int leadId;
  final Map<String, dynamic> fields;

  UpdateLead({required this.leadId, required this.fields});
}
