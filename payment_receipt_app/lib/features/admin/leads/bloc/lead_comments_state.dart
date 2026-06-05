part of 'lead_comments_bloc.dart';

abstract class LeadCommentsState {}

class CommentsInitial extends LeadCommentsState {}

class CommentsLoading extends LeadCommentsState {}

class CommentsLoaded extends LeadCommentsState {
  final List<LeadCommentModel> comments;

  CommentsLoaded({required this.comments});
}

class CommentsError extends LeadCommentsState {
  final String message;
  final CommentErrorType errorType;

  CommentsError({
    required this.message,
    this.errorType = CommentErrorType.unknown,
  });
}
