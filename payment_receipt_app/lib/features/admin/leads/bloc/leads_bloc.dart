import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../models/lead_model.dart';
import '../models/mapping_result.dart';
import '../services/leads_service.dart';
import '../services/file_saver_service.dart';

part 'leads_event.dart';
part 'leads_state.dart';

/// Transformer que aplica debounce a los eventos.
/// Espera [duration] después del último evento antes de procesarlo.
EventTransformer<T> debounce<T>(Duration duration) {
  return (events, mapper) {
    return events
        .transform(_DebounceStreamTransformer<T>(duration))
        .asyncExpand(mapper);
  };
}

/// StreamTransformer que implementa debounce sin dependencias externas.
class _DebounceStreamTransformer<T> extends StreamTransformerBase<T, T> {
  final Duration duration;

  _DebounceStreamTransformer(this.duration);

  @override
  Stream<T> bind(Stream<T> stream) {
    return Stream<T>.eventTransformed(
      stream,
      (sink) => _DebounceSink<T>(sink, duration),
    );
  }
}

class _DebounceSink<T> implements EventSink<T> {
  final EventSink<T> _outputSink;
  final Duration _duration;
  Timer? _timer;

  _DebounceSink(this._outputSink, this._duration);

  @override
  void add(T event) {
    _timer?.cancel();
    _timer = Timer(_duration, () {
      _outputSink.add(event);
    });
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() {
    _timer?.cancel();
    _outputSink.close();
  }
}

class LeadsBloc extends Bloc<LeadsEvent, LeadsState> {
  final LeadsService leadsService;

  /// Almacena referencia a los bytes del archivo subido para usarlo en ConfirmImport.
  List<int>? _uploadedFileBytes;
  String? _uploadedFileName;

  LeadsBloc({required this.leadsService}) : super(LeadsInitial()) {
    on<LoadLeads>(_onLoadLeads);
    on<SearchLeads>(
      _onSearchLeads,
      transformer: debounce(const Duration(milliseconds: 300)),
    );
    on<UploadExcel>(_onUploadExcel);
    on<ConfirmImport>(_onConfirmImport);
    on<LoadLeadDetail>(_onLoadLeadDetail);
    on<UpdateLead>(_onUpdateLead);
    on<ClearSearch>(_onClearSearch);
    on<ExportLeads>(_onExportLeads);
    on<DeleteLead>(_onDeleteLead);
  }

  Future<void> _onLoadLeads(LoadLeads event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    try {
      final result = await LeadsService.getLeads(
        page: event.page,
        sort: event.sortBy ?? 'id',
        direction: event.direction ?? 'desc',
        unassigned: event.unassigned,
        advisorId: event.advisorId,
        pais: event.pais,
      );
      emit(LeadsLoaded(
        leads: result['leads'] as List<LeadModel>,
        totalPages: result['totalPages'] as int,
        currentPage: result['currentPage'] as int,
      ));
    } catch (e) {
      emit(LeadsError(message: 'Error al cargar leads: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onSearchLeads(SearchLeads event, Emitter<LeadsState> emit) async {
    if (event.term.trim().isEmpty) {
      add(LoadLeads(page: event.page));
      return;
    }
    emit(LeadsLoading());
    try {
      final result = await LeadsService.searchLeads(
        term: event.term,
        page: event.page,
      );
      emit(LeadsLoaded(
        leads: result['leads'] as List<LeadModel>,
        totalPages: result['totalPages'] as int,
        currentPage: result['currentPage'] as int,
      ));
    } catch (e) {
      emit(LeadsError(message: 'Error al buscar leads: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onUploadExcel(UploadExcel event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    try {
      _uploadedFileBytes = event.fileBytes;
      _uploadedFileName = event.fileName;
      final mapping = await LeadsService.uploadExcel(event.fileBytes, event.fileName);
      emit(MappingPreviewLoaded(mapping: mapping));
    } catch (e) {
      emit(LeadsError(message: 'Error al procesar archivo Excel: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onConfirmImport(ConfirmImport event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    try {
      if (_uploadedFileBytes == null) {
        emit(LeadsError(message: 'No hay archivo cargado para importar'));
        return;
      }
      final result = await LeadsService.confirmImport(
        _uploadedFileBytes!,
        _uploadedFileName ?? 'file.xlsx',
        event.mapping,
      );
      _uploadedFileBytes = null;
      _uploadedFileName = null;
      emit(ImportCompleted(
        successCount: result.successCount,
        errorCount: result.errorCount,
        duplicateCount: result.duplicateCount,
      ));
    } catch (e) {
      emit(LeadsError(message: 'Error al confirmar importación: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onLoadLeadDetail(LoadLeadDetail event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    try {
      final lead = await LeadsService.getLeadById(event.leadId);
      emit(LeadDetailLoaded(lead: lead));
    } catch (e) {
      emit(LeadsError(message: 'Error al cargar detalle del lead: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onUpdateLead(UpdateLead event, Emitter<LeadsState> emit) async {
    emit(LeadsLoading());
    try {
      final updatedLead = await LeadsService.updateLead(event.lead);
      emit(LeadDetailLoaded(lead: updatedLead));
    } catch (e) {
      emit(LeadsError(message: 'Error al actualizar lead: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onClearSearch(ClearSearch event, Emitter<LeadsState> emit) async {
    add(LoadLeads());
  }

  Future<void> _onExportLeads(ExportLeads event, Emitter<LeadsState> emit) async {
    emit(ExportInProgress());
    try {
      final bytes = await LeadsService.exportLeads();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'leads_export_$timestamp.xlsx';
      final filePath = await FileSaverService.saveFile(bytes, fileName);
      emit(ExportCompleted(filePath: filePath));
    } catch (e) {
      emit(LeadsError(message: 'Error al exportar leads: ${_parseErrorMessage(e)}'));
    }
  }

  Future<void> _onDeleteLead(DeleteLead event, Emitter<LeadsState> emit) async {
    try {
      await LeadsService.deleteLead(event.leadId);
      // Recargar la lista después de eliminar
      add(LoadLeads());
    } catch (e) {
      emit(LeadsError(message: 'Error al eliminar lead: ${_parseErrorMessage(e)}'));
    }
  }

  /// Extrae un mensaje legible de la excepción.
  String _parseErrorMessage(Object error) {
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return message.substring('Exception: '.length);
    }
    return message;
  }
}
