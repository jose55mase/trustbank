part of 'lead_comments_bloc.dart';

abstract class LeadCommentsEvent {}

class LoadComments extends LeadCommentsEvent {
  final int leadId;

  LoadComments({required this.leadId});
}

class AddComment extends LeadCommentsEvent {
  final int leadId;
  final String text;

  AddComment({required this.leadId, required this.text});
}

class EditComment extends LeadCommentsEvent {
  final int leadId;
  final int commentId;
  final String text;

  EditComment({
    required this.leadId,
    required this.commentId,
    required this.text,
  });
}

class DeleteComment extends LeadCommentsEvent {
  final int leadId;
  final int commentId;

  DeleteComment({required this.leadId, required this.commentId});
}
