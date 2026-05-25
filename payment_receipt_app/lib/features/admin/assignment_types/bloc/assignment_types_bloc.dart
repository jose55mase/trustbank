import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../models/assignment_type.dart';
import '../../../../services/assignment_types_service.dart';

part 'assignment_types_event.dart';
part 'assignment_types_state.dart';

class AssignmentTypesBloc
    extends Bloc<AssignmentTypesEvent, AssignmentTypesState> {
  AssignmentTypesBloc() : super(AssignmentTypesInitial()) {
    on<LoadAssignmentTypes>(_onLoadAssignmentTypes);
    on<CreateAssignmentType>(_onCreateAssignmentType);
    on<UpdateAssignmentType>(_onUpdateAssignmentType);
    on<DeleteAssignmentType>(_onDeleteAssignmentType);
  }

  Future<void> _onLoadAssignmentTypes(
    LoadAssignmentTypes event,
    Emitter<AssignmentTypesState> emit,
  ) async {
    emit(AssignmentTypesLoading());
    try {
      final types = await AssignmentTypesService.getAll();
      emit(AssignmentTypesLoaded(types: types));
    } catch (e) {
      emit(AssignmentTypesError(
        message:
            'Error al cargar tipos de asignación: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onCreateAssignmentType(
    CreateAssignmentType event,
    Emitter<AssignmentTypesState> emit,
  ) async {
    emit(AssignmentTypesLoading());
    try {
      await AssignmentTypesService.create(
        AssignmentTypeRequest(
          name: event.name,
          description: event.description,
          active: event.active,
          filterValue: event.filterValue,
        ),
      );
      add(LoadAssignmentTypes());
    } catch (e) {
      emit(AssignmentTypesError(
        message:
            'Error al crear tipo de asignación: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onUpdateAssignmentType(
    UpdateAssignmentType event,
    Emitter<AssignmentTypesState> emit,
  ) async {
    emit(AssignmentTypesLoading());
    try {
      await AssignmentTypesService.update(
        event.id,
        AssignmentTypeRequest(
          name: event.name,
          description: event.description,
          active: event.active,
          filterValue: event.filterValue,
        ),
      );
      add(LoadAssignmentTypes());
    } catch (e) {
      emit(AssignmentTypesError(
        message:
            'Error al actualizar tipo de asignación: ${_parseErrorMessage(e)}',
      ));
    }
  }

  Future<void> _onDeleteAssignmentType(
    DeleteAssignmentType event,
    Emitter<AssignmentTypesState> emit,
  ) async {
    emit(AssignmentTypesLoading());
    try {
      await AssignmentTypesService.delete(event.id);
      add(LoadAssignmentTypes());
    } catch (e) {
      emit(AssignmentTypesError(
        message:
            'Error al eliminar tipo de asignación: ${_parseErrorMessage(e)}',
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
