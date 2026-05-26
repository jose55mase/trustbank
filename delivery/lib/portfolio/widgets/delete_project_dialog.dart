import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_project.dart';
import '../providers/portfolio_providers.dart';

/// Shows a confirmation dialog before deleting a project.
///
/// On confirmation, deletes the project from Firestore and removes
/// associated images from Storage. Shows a SnackBar on failure.
///
/// Validates: Requirements 5.4, 5.6
class DeleteProjectDialog extends ConsumerStatefulWidget {
  /// The project to be deleted.
  final PortfolioProject project;

  const DeleteProjectDialog({super.key, required this.project});

  /// Shows the delete confirmation dialog and handles the deletion flow.
  ///
  /// Returns `true` if the project was successfully deleted, `false` otherwise.
  static Future<bool> show(BuildContext context, PortfolioProject project) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => DeleteProjectDialog(project: project),
    );
    return result ?? false;
  }

  @override
  ConsumerState<DeleteProjectDialog> createState() =>
      _DeleteProjectDialogState();
}

class _DeleteProjectDialogState extends ConsumerState<DeleteProjectDialog> {
  bool _isDeleting = false;

  Future<void> _handleDelete() async {
    setState(() => _isDeleting = true);

    try {
      final projectRepo = ref.read(projectRepositoryProvider);
      final imageRepo = ref.read(imageStorageProvider);

      // Delete associated images from Storage
      final imageUrls = [
        widget.project.mainImageUrl,
        ...widget.project.additionalImageUrls,
      ];

      for (final url in imageUrls) {
        if (url.isNotEmpty) {
          try {
            await imageRepo.deleteImage(url);
          } catch (_) {
            // Continue deleting other images even if one fails
          }
        }
      }

      // Delete the project document from Firestore
      await projectRepo.deleteProject(widget.project.id);

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo eliminar el proyecto. Intente nuevamente.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Confirmar eliminación'),
      content: Text("¿Eliminar '${widget.project.title}'?"),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isDeleting ? null : _handleDelete,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Eliminar'),
        ),
      ],
    );
  }
}
