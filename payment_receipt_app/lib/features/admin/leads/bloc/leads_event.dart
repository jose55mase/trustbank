part of 'leads_bloc.dart';

abstract class LeadsEvent {}

class LoadLeads extends LeadsEvent {
  final int page;
  final String? sortBy;
  final String? direction;
  final bool? unassigned;
  final int? advisorId;
  final String? pais;

  LoadLeads({
    this.page = 0,
    this.sortBy,
    this.direction,
    this.unassigned,
    this.advisorId,
    this.pais,
  });
}

class SearchLeads extends LeadsEvent {
  final String term;
  final int page;

  SearchLeads({required this.term, this.page = 0});
}

class UploadExcel extends LeadsEvent {
  final List<int> fileBytes;
  final String fileName;

  UploadExcel({required this.fileBytes, required this.fileName});
}

class ConfirmImport extends LeadsEvent {
  final Map<int, String?> mapping;

  ConfirmImport({required this.mapping});
}

class LoadLeadDetail extends LeadsEvent {
  final int leadId;

  LoadLeadDetail({required this.leadId});
}

class UpdateLead extends LeadsEvent {
  final LeadModel lead;

  UpdateLead({required this.lead});
}

class ClearSearch extends LeadsEvent {}

class ExportLeads extends LeadsEvent {}

class DeleteLead extends LeadsEvent {
  final int leadId;

  DeleteLead({required this.leadId});
}
