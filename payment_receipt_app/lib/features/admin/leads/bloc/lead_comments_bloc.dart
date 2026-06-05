import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/lead_comment_model.dart';
import '../services/comment_api_exception.dart';
import '../services/lead_comments_service.dart';

part 'lead_comments_event.dart';
part 'lead_comments_state.dart';

class LeadCommentsBloc extends Bloc<LeadCommentsEvent, LeadCommentsState> {
  LeadCommentsBloc() : super(CommentsInitial()) {
    on<LoadComments>(_onLoadComments);
    on<AddComment>(_onAddComment);
    on<EditComment>(_onEditComment);
    on<DeleteComment>(_onDeleteComment);
  }

  Future<void> _onLoadComments(
    LoadComments event,
    Emitter<LeadCommentsState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      final comments = await LeadCommentsService.getComments(event.leadId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(_buildErrorState(e));
    }
  }

  Future<void> _onAddComment(
    AddComment event,
    Emitter<LeadCommentsState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      await LeadCommentsService.createComment(event.leadId, event.text);
      // Reload comments to reflect the new addition
      final comments = await LeadCommentsService.getComments(event.leadId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(_buildErrorState(e));
    }
  }

  Future<void> _onEditComment(
    EditComment event,
    Emitter<LeadCommentsState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      await LeadCommentsService.updateComment(
        event.leadId,
        event.commentId,
        event.text,
      );
      // Reload comments to reflect the edit
      final comments = await LeadCommentsService.getComments(event.leadId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(_buildErrorState(e));
    }
  }

  Future<void> _onDeleteComment(
    DeleteComment event,
    Emitter<LeadCommentsState> emit,
  ) async {
    emit(CommentsLoading());
    try {
      await LeadCommentsService.deleteComment(event.leadId, event.commentId);
      // Reload comments to reflect the deletion
      final comments = await LeadCommentsService.getComments(event.leadId);
      emit(CommentsLoaded(comments: comments));
    } catch (e) {
      emit(_buildErrorState(e));
    }
  }

  /// Extracts error type and message from the exception.
  CommentsError _buildErrorState(Object error) {
    if (error is CommentApiException) {
      return CommentsError(
        message: error.message,
        errorType: error.type,
      );
    }
    final message = error.toString();
    if (message.startsWith('Exception: ')) {
      return CommentsError(
        message: message.substring('Exception: '.length),
      );
    }
    return CommentsError(message: message);
  }
}
