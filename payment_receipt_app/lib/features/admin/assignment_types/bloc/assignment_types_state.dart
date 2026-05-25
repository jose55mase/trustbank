part of 'assignment_types_bloc.dart';

abstract class AssignmentTypesState {}

class AssignmentTypesInitial extends AssignmentTypesState {}

class AssignmentTypesLoading extends AssignmentTypesState {}

class AssignmentTypesLoaded extends AssignmentTypesState {
  final List<AssignmentType> types;

  AssignmentTypesLoaded({required this.types});
}

class AssignmentTypesError extends AssignmentTypesState {
  final String message;

  AssignmentTypesError({required this.message});
}
