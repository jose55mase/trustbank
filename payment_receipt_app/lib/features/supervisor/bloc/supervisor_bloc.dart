import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../models/lead_model.dart';
import '../../../services/supervisor_service.dart';

part 'supervisor_event.dart';
part 'supervisor_state.dart';

/// Transformer que aplica debounce a los eventos de búsqueda.
EventTransformer<T> _debounce<T>(Duration duration) {
  return (events, mapper) {
    return events
        .transform(_DebounceStreamTransformer<T>(duration))
        .asyncExpand(mapper);
  };
}

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

/// BLoC para el panel del supervisor.
/// Gestiona la carga, búsqueda, selección y actualización de leads
/// filtrados por el tipo de asignación del supervisor.
class SupervisorBloc extends Bloc<SupervisorEvent, SupervisorState> {
  SupervisorBloc() : super(SupervisorInitial()) {
    on<LoadSupervisorLeads>(_onLoadLeads);
    on<SearchSupervisorLeads>(
      _onSearchLeads,
      transformer: _debounce(const Duration(milliseconds: 300)),
    );
    on<SelectLead>(_onSelectLead);
    on<UpdateLead>(_onUpdateLead);
  }

  Future<void> _onLoadLeads(
    LoadSupervisorLeads event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorLoading());
    try {
      final result = await SupervisorService.getLeads(
        page: event.page,
        size: event.size,
        status: event.status,
      );
      emit(SupervisorLeadsLoaded(
        leads: result['leads'] as List<LeadModel>,
        totalPages: result['totalPages'] as int,
        currentPage: result['currentPage'] as int,
        totalItems: result['totalItems'] as int,
        hasNext: result['hasNext'] as bool,
        hasPrevious: result['hasPrevious'] as bool,
      ));
    } catch (e) {
      emit(SupervisorError(
        message: 'Error al cargar leads: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onSearchLeads(
    SearchSupervisorLeads event,
    Emitter<SupervisorState> emit,
  ) async {
    if (event.term.trim().isEmpty) {
      add(LoadSupervisorLeads(page: event.page, size: event.size));
      return;
    }
    emit(SupervisorLoading());
    try {
      final result = await SupervisorService.searchLeads(
        term: event.term,
        page: event.page,
        size: event.size,
      );
      emit(SupervisorLeadsLoaded(
        leads: result['leads'] as List<LeadModel>,
        totalPages: result['totalPages'] as int,
        currentPage: result['currentPage'] as int,
        totalItems: result['totalItems'] as int,
        hasNext: result['hasNext'] as bool,
        hasPrevious: result['hasPrevious'] as bool,
      ));
    } catch (e) {
      emit(SupervisorError(
        message: 'Error al buscar leads: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onSelectLead(
    SelectLead event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorLoading());
    try {
      final lead = await SupervisorService.getLeadById(event.leadId);
      emit(SupervisorLeadDetail(lead: lead));
    } catch (e) {
      emit(SupervisorError(
        message: 'Error al cargar detalle del lead: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onUpdateLead(
    UpdateLead event,
    Emitter<SupervisorState> emit,
  ) async {
    emit(SupervisorLoading());
    try {
      final updatedLead = await SupervisorService.updateLead(
        event.leadId,
        event.fields,
      );
      emit(SupervisorLeadUpdated(lead: updatedLead));
    } catch (e) {
      emit(SupervisorError(
        message: 'Error al actualizar lead: ${_parseErrorMessage(e)}',
      ));
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
