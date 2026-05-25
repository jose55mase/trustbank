part of 'leads_bloc.dart';

abstract class LeadsState {}

class LeadsInitial extends LeadsState {}

class LeadsLoading extends LeadsState {}

class LeadsLoaded extends LeadsState {
  final List<LeadModel> leads;
  final int totalPages;
  final int currentPage;

  LeadsLoaded({
    required this.leads,
    required this.totalPages,
    required this.currentPage,
  });
}

class LeadDetailLoaded extends LeadsState {
  final LeadModel lead;

  LeadDetailLoaded({required this.lead});
}

class MappingPreviewLoaded extends LeadsState {
  final MappingResult mapping;

  MappingPreviewLoaded({required this.mapping});
}

class ImportCompleted extends LeadsState {
  final int successCount;
  final int errorCount;
  final int duplicateCount;

  ImportCompleted({
    required this.successCount,
    required this.errorCount,
    this.duplicateCount = 0,
  });
}

class ExportInProgress extends LeadsState {}

class ExportCompleted extends LeadsState {
  final String filePath;

  ExportCompleted({required this.filePath});
}

class LeadsError extends LeadsState {
  final String message;

  LeadsError({required this.message});
}
