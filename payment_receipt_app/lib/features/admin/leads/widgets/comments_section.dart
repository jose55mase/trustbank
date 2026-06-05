import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/colors/tb_colors.dart';
import '../../../../design_system/spacing/tb_spacing.dart';
import '../../../../design_system/typography/tb_typography.dart';
import '../../../../services/auth_service.dart';
import '../bloc/lead_comments_bloc.dart';
import '../models/lead_comment_model.dart';
import '../services/comment_api_exception.dart';

/// Sección de comentarios para el panel de detalle de un Lead.
///
/// Muestra el comentario legado (si existe) con badge "Legado" y sin controles,
/// seguido de los comentarios con autor en orden cronológico (más antiguo primero).
/// Cada comentario muestra nombre del autor, timestamp, badge "Editado" si aplica,
/// y botones de editar/eliminar solo si el usuario actual es el autor.
/// Al final incluye un campo de texto y botón para agregar nuevos comentarios.
class CommentsSection extends StatefulWidget {
  final int leadId;

  const CommentsSection({super.key, required this.leadId});

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  int? _currentUserId;
  String? _validationError;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final userId = await AuthService.getCurrentUserId();
    if (mounted) {
      setState(() {
        _currentUserId = userId;
      });
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _submitComment() {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    // Clear any previous validation error
    setState(() {
      _validationError = null;
    });

    context.read<LeadCommentsBloc>().add(
          AddComment(leadId: widget.leadId, text: text),
        );
    _commentController.clear();
  }

  void _showEditDialog(LeadCommentModel comment) {
    final editController = TextEditingController(text: comment.text);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Editar comentario'),
          content: TextField(
            controller: editController,
            maxLines: 4,
            maxLength: 2000,
            decoration: const InputDecoration(
              hintText: 'Escribe tu comentario...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                final newText = editController.text.trim();
                if (newText.isNotEmpty && comment.id != null) {
                  context.read<LeadCommentsBloc>().add(
                        EditComment(
                          leadId: widget.leadId,
                          commentId: comment.id!,
                          text: newText,
                        ),
                      );
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteConfirmation(LeadCommentModel comment) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Eliminar comentario'),
          content: const Text(
            '¿Estás seguro de que deseas eliminar este comentario? Esta acción no se puede deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (comment.id != null) {
                  context.read<LeadCommentsBloc>().add(
                        DeleteComment(
                          leadId: widget.leadId,
                          commentId: comment.id!,
                        ),
                      );
                }
                Navigator.of(dialogContext).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.error,
                foregroundColor: Colors.white,
              ),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  String _formatTimestamp(DateTime dateTime) {
    final months = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic',
    ];
    final day = dateTime.day;
    final month = months[dateTime.month - 1];
    final year = dateTime.year;
    final hour = DateFormat('HH:mm').format(dateTime);
    return '$day $month $year, $hour';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LeadCommentsBloc, LeadCommentsState>(
      listener: _handleErrorState,
      child: Container(
        decoration: BoxDecoration(
          color: TBColors.surface,
          borderRadius: BorderRadius.circular(TBSpacing.radiusLg),
          border: Border.all(color: TBColors.grey300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const Divider(height: 1, color: TBColors.grey300),
            _buildBody(),
            const Divider(height: 1, color: TBColors.grey300),
            _buildInputSection(),
          ],
        ),
      ),
    );
  }

  /// Handles different error types with appropriate UI feedback.
  void _handleErrorState(BuildContext context, LeadCommentsState state) {
    if (state is! CommentsError) return;

    switch (state.errorType) {
      case CommentErrorType.network:
        _showNetworkErrorSnackbar(context, state.message);
        break;
      case CommentErrorType.validation:
        // Show inline validation message below the input field
        setState(() {
          _validationError = state.message;
        });
        break;
      case CommentErrorType.forbidden:
        _showForbiddenDialog(context);
        break;
      case CommentErrorType.notFound:
        // Refresh comments list (stale data — comment may have been deleted)
        context
            .read<LeadCommentsBloc>()
            .add(LoadComments(leadId: widget.leadId));
        break;
      case CommentErrorType.unauthorized:
        // Already handled by SessionManager in the service layer
        break;
      case CommentErrorType.unknown:
        // Fall through to the default inline error display (already rendered by BlocBuilder)
        break;
    }
  }

  /// Shows a snackbar with a retry option for network errors.
  void _showNetworkErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: TBColors.error,
        action: SnackBarAction(
          label: 'Reintentar',
          textColor: Colors.white,
          onPressed: () {
            context
                .read<LeadCommentsBloc>()
                .add(LoadComments(leadId: widget.leadId));
          },
        ),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  /// Shows a dialog indicating the user does not have permission.
  void _showForbiddenDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          icon: const Icon(Icons.lock_outline, color: TBColors.error, size: 40),
          title: const Text('Sin permiso'),
          content: const Text(
            'No tienes permiso para realizar esta acción.',
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: TBColors.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: TBColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.comment_outlined,
              color: TBColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: TBSpacing.sm),
          Expanded(
            child: Text(
              'Comentarios',
              style: TBTypography.titleLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return BlocBuilder<LeadCommentsBloc, LeadCommentsState>(
      builder: (context, state) {
        if (state is CommentsLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: TBSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is CommentsError) {
          return _buildErrorState(state.message);
        }

        if (state is CommentsLoaded) {
          final comments = state.comments;
          if (comments.isEmpty) {
            return _buildEmptyState();
          }
          return _buildCommentsList(comments);
        }

        // CommentsInitial
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: TBSpacing.xl),
          child: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }

  Widget _buildErrorState(String message) {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(TBSpacing.md),
        decoration: BoxDecoration(
          color: TBColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: TBColors.error, size: 20),
            const SizedBox(width: TBSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: TBTypography.bodyMedium.copyWith(
                  color: TBColors.error,
                ),
              ),
            ),
            const SizedBox(width: TBSpacing.sm),
            TextButton(
              onPressed: () {
                context
                    .read<LeadCommentsBloc>()
                    .add(LoadComments(leadId: widget.leadId));
              },
              child: Text(
                'Reintentar',
                style: TBTypography.buttonMedium.copyWith(
                  color: TBColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.lg),
      child: Center(
        child: Column(
          children: [
            const Icon(
              Icons.chat_bubble_outline,
              size: 40,
              color: TBColors.grey400,
            ),
            const SizedBox(height: TBSpacing.sm),
            Text(
              'No hay comentarios aún',
              style: TBTypography.bodyMedium.copyWith(
                color: TBColors.grey600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentsList(List<LeadCommentModel> comments) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.md,
        vertical: TBSpacing.sm,
      ),
      child: Column(
        children: comments.map((comment) {
          if (comment.isLegacy) {
            return _buildLegacyComment(comment);
          }
          return _buildAuthoredComment(comment);
        }).toList(),
      ),
    );
  }

  Widget _buildLegacyComment(LeadCommentModel comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.grey100,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildBadge('Legado', TBColors.warning),
              const Spacer(),
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            comment.text,
            style: TBTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildAuthoredComment(LeadCommentModel comment) {
    final isOwner = _currentUserId != null && comment.userId == _currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: TBSpacing.sm),
      padding: const EdgeInsets.all(TBSpacing.md),
      decoration: BoxDecoration(
        color: TBColors.white,
        borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
        border: Border.all(color: TBColors.grey300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Text(
                      comment.authorName ?? 'Usuario',
                      style: TBTypography.labelMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: TBColors.grey700,
                      ),
                    ),
                    const SizedBox(width: TBSpacing.sm),
                    Text(
                      _formatTimestamp(comment.createdAt),
                      style: TBTypography.bodySmall.copyWith(
                        color: TBColors.grey500,
                      ),
                    ),
                    if (comment.editedAt != null) ...[
                      const SizedBox(width: TBSpacing.sm),
                      _buildBadge('Editado', TBColors.grey500),
                    ],
                  ],
                ),
              ),
              if (isOwner) ...[
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  color: TBColors.grey600,
                  tooltip: 'Editar',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showEditDialog(comment),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  color: TBColors.error,
                  tooltip: 'Eliminar',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  padding: EdgeInsets.zero,
                  onPressed: () => _showDeleteConfirmation(comment),
                ),
              ],
            ],
          ),
          const SizedBox(height: TBSpacing.sm),
          Text(
            comment.text,
            style: TBTypography.bodyMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: TBSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(TBSpacing.radiusSm),
      ),
      child: Text(
        label,
        style: TBTypography.labelSmall.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Padding(
      padding: const EdgeInsets.all(TBSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: TextField(
                  controller: _commentController,
                  maxLines: 3,
                  minLines: 1,
                  maxLength: 2000,
                  onChanged: (_) {
                    // Clear validation error when user starts typing
                    if (_validationError != null) {
                      setState(() {
                        _validationError = null;
                      });
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Agregar comentario...',
                    hintStyle: TBTypography.bodyMedium.copyWith(
                      color: TBColors.grey400,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: _validationError != null
                            ? TBColors.error
                            : TBColors.grey300,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: _validationError != null
                            ? TBColors.error
                            : TBColors.grey300,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                      borderSide: BorderSide(
                        color: _validationError != null
                            ? TBColors.error
                            : TBColors.primary,
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: TBSpacing.md,
                      vertical: TBSpacing.sm,
                    ),
                    counterText: '',
                  ),
                ),
              ),
              const SizedBox(width: TBSpacing.sm),
              IconButton(
                onPressed: _submitComment,
                icon: const Icon(Icons.send),
                color: TBColors.primary,
                tooltip: 'Enviar comentario',
                style: IconButton.styleFrom(
                  backgroundColor: TBColors.primary.withOpacity(0.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TBSpacing.radiusMd),
                  ),
                ),
              ),
            ],
          ),
          if (_validationError != null)
            Padding(
              padding: const EdgeInsets.only(top: TBSpacing.xs, left: TBSpacing.sm),
              child: Text(
                _validationError!,
                style: TBTypography.bodySmall.copyWith(
                  color: TBColors.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
