part of 'assignment_types_bloc.dart';

abstract class AssignmentTypesEvent {}

class LoadAssignmentTypes extends AssignmentTypesEvent {}

class CreateAssignmentType extends AssignmentTypesEvent {
  final String name;
  final String? description;
  final bool? active;
  final String? filterValue;

  CreateAssignmentType({
    required this.name,
    this.description,
    this.active,
    this.filterValue,
  });
}

class UpdateAssignmentType extends AssignmentTypesEvent {
  final int id;
  final String name;
  final String? description;
  final bool active;
  final String? filterValue;

  UpdateAssignmentType({
    required this.id,
    required this.name,
    this.description,
    required this.active,
    this.filterValue,
  });
}

class DeleteAssignmentType extends AssignmentTypesEvent {
  final int id;

  DeleteAssignmentType({required this.id});
}
