import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_project.dart';
import '../providers/portfolio_providers.dart';
import '../theme/portfolio_theme.dart';

/// Editor widget for carousel content (featured projects).
///
/// Allows the admin to edit the title (max 100 chars), description (max 300 chars),
/// and image of each carousel item (featured project).
///
/// Carousel items are derived from projects with `isFeatured == true`.
/// Editing carousel content means editing the project's title, description, and mainImageUrl.
///
/// Validates: Requirements 6.5
class CarouselContentEditor extends ConsumerStatefulWidget {
  const CarouselContentEditor({super.key});

  /// Validates the carousel item title.
  /// Returns null if valid, or an error message string.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es obligatorio';
    }
    if (value.length > 100) {
      return 'El título no puede exceder 100 caracteres';
    }
    return null;
  }

  /// Validates the carousel item description.
  /// Returns null if valid, or an error message string.
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (value.length > 300) {
      return 'La descripción no puede exceder 300 caracteres';
    }
    return null;
  }

  /// Validates an image file (format and size).
  /// Returns null if valid, or an error message string.
  static String? validateImageFile(Uint8List bytes, String filename) {
    final ext = filename.split('.').last.toLowerCase();
    const allowedExtensions = ['png', 'jpg', 'jpeg', 'webp'];
    if (!allowedExtensions.contains(ext)) {
      return 'Formato no soportado. Use PNG, JPG o WebP';
    }
    const maxSize = 5 * 1024 * 1024; // 5 MB
    if (bytes.length > maxSize) {
      return 'La imagen no puede exceder 5 MB';
    }
    return null;
  }

  @override
  ConsumerState<CarouselContentEditor> createState() =>
      CarouselContentEditorState();
}

class CarouselContentEditorState extends ConsumerState<CarouselContentEditor> {
  /// Tracks which project is currently being edited (by project id).
  String? _editingProjectId;

  /// Controllers for the editing fields.
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  /// Validation errors for the currently editing item.
  String? _titleError;
  String? _descriptionError;

  /// Image replacement state per project id.
  final Map<String, _ImageReplacementState> _imageReplacements = {};

  /// Whether a save operation is in progress.
  bool _isSaving = false;

  /// Global save error message.
  String? _saveError;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Starts editing a carousel item (featured project).
  void startEditing(PortfolioProject project) {
    setState(() {
      _editingProjectId = project.id;
      _titleController.text = project.title;
      _descriptionController.text = project.description;
      _titleError = null;
      _descriptionError = null;
      _saveError = null;
    });
  }

  /// Cancels the current editing operation.
  void cancelEditing() {
    setState(() {
      _editingProjectId = null;
      _titleController.clear();
      _descriptionController.clear();
      _titleError = null;
      _descriptionError = null;
    });
  }

  /// Saves the edited title and description for the given project.
  Future<void> saveContent(PortfolioProject project) async {
    final titleValue = _titleController.text;
    final descriptionValue = _descriptionController.text;

    // Validate
    final titleErr = CarouselContentEditor.validateTitle(titleValue);
    final descErr = CarouselContentEditor.validateDescription(descriptionValue);

    if (titleErr != null || descErr != null) {
      setState(() {
        _titleError = titleErr;
        _descriptionError = descErr;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _titleError = null;
      _descriptionError = null;
      _saveError = null;
    });

    try {
      final projectRepo = ref.read(projectRepositoryProvider);
      final updatedProject = project.copyWith(
        title: titleValue.trim(),
        description: descriptionValue.trim(),
        updatedAt: DateTime.now(),
      );
      await projectRepo.updateProject(updatedProject);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _editingProjectId = null;
          _titleController.clear();
          _descriptionController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = 'No se pudo guardar el cambio. Intente de nuevo.';
        });
      }
    }
  }

  /// Replaces the image for a carousel item (featured project).
  /// Called programmatically (e.g., from a file picker or tests).
  Future<void> replaceImage(
    PortfolioProject project,
    Uint8List bytes,
    String filename,
  ) async {
    // Validate format and size
    final error = CarouselContentEditor.validateImageFile(bytes, filename);
    if (error != null) {
      setState(() {
        _imageReplacements[project.id] = _ImageReplacementState(
          error: error,
          filename: filename,
        );
      });
      return;
    }

    // Also validate via repository
    final imageRepo = ref.read(imageStorageProvider);
    final isValid = await imageRepo.validateImage(bytes, filename);
    if (!isValid) {
      setState(() {
        _imageReplacements[project.id] = _ImageReplacementState(
          error: 'Formato no soportado. Use PNG, JPG o WebP (máx 5 MB)',
          filename: filename,
        );
      });
      return;
    }

    setState(() {
      _imageReplacements[project.id] = _ImageReplacementState(
        filename: filename,
        isSaving: true,
      );
      _saveError = null;
    });

    try {
      // Upload the new image
      final url = await imageRepo.uploadImage(bytes, filename);

      // Update the project with the new image URL
      final projectRepo = ref.read(projectRepositoryProvider);
      final updatedProject = project.copyWith(
        mainImageUrl: url,
        updatedAt: DateTime.now(),
      );
      await projectRepo.updateProject(updatedProject);

      if (mounted) {
        setState(() {
          _imageReplacements.remove(project.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageReplacements[project.id] = _ImageReplacementState(
            filename: filename,
            error: 'No se pudo guardar el cambio. Intente de nuevo.',
          );
          _saveError = 'No se pudo guardar el cambio. Intente de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final featuredAsync = ref.watch(featuredProjectsProvider);

    return Theme(
      data: PortfolioTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        appBar: AppBar(
          title: const Text('Editar Carrusel'),
          backgroundColor: PortfolioTheme.surface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_saveError != null) ...[
                    _ErrorBanner(message: _saveError!),
                    const SizedBox(height: 16),
                  ],
                  featuredAsync.when(
                    data: (projects) => _buildProjectList(projects),
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (error, _) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error al cargar proyectos destacados: $error',
                        style: TextStyle(color: PortfolioTheme.error),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProjectList(List<PortfolioProject> projects) {
    if (projects.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No hay proyectos destacados para el carrusel',
            style: TextStyle(
              color: PortfolioTheme.textSecondary,
              fontSize: 16,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Elementos del Carrusel (${projects.length})',
          style: TextStyle(
            color: PortfolioTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...projects.map(_buildCarouselItemCard),
      ],
    );
  }

  Widget _buildCarouselItemCard(PortfolioProject project) {
    final isEditing = _editingProjectId == project.id;
    final imageReplacement = _imageReplacements[project.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: PortfolioTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row with project title and edit button
            Row(
              children: [
                Icon(
                  Icons.view_carousel,
                  size: 20,
                  color: PortfolioTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isEditing ? 'Editando...' : project.title,
                    style: TextStyle(
                      color: PortfolioTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      size: 20,
                      color: PortfolioTheme.primaryBlue,
                    ),
                    onPressed: () => startEditing(project),
                    tooltip: 'Editar',
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Image section
            _buildImageSection(project, imageReplacement),
            const SizedBox(height: 12),

            // Title and description editing or display
            if (isEditing) ...[
              // Title field
              TextField(
                controller: _titleController,
                maxLength: 100,
                decoration: InputDecoration(
                  labelText: 'Título (máx. 100 caracteres)',
                  errorText: _titleError,
                  counterText: '${_titleController.text.length}/100',
                  filled: true,
                  fillColor: PortfolioTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PortfolioTheme.divider),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Description field
              TextField(
                controller: _descriptionController,
                maxLength: 300,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Descripción (máx. 300 caracteres)',
                  errorText: _descriptionError,
                  counterText:
                      '${_descriptionController.text.length}/300',
                  filled: true,
                  fillColor: PortfolioTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PortfolioTheme.divider),
                  ),
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : cancelEditing,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => saveContent(project),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PortfolioTheme.primaryBlue,
                      foregroundColor: PortfolioTheme.accentBlack,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child:
                                CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ] else ...[
              // Display current description
              Text(
                project.description,
                style: TextStyle(
                  color: PortfolioTheme.textSecondary,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection(
    PortfolioProject project,
    _ImageReplacementState? replacement,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image preview
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            project.mainImageUrl,
            height: 120,
            width: double.infinity,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: PortfolioTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image,
                        color: PortfolioTheme.textHint),
                    const SizedBox(height: 4),
                    Text(
                      project.title,
                      style: TextStyle(
                        color: PortfolioTheme.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Replace image button
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: replacement?.isSaving == true ? null : () {},
              icon: const Icon(Icons.upload_file, size: 18),
              label: const Text('Reemplazar imagen'),
            ),
            if (replacement?.isSaving == true) ...[
              const SizedBox(width: 12),
              const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ],
          ],
        ),
        // Image error message
        if (replacement?.error != null) ...[
          const SizedBox(height: 4),
          Text(
            replacement!.error!,
            style: TextStyle(
              color: PortfolioTheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }
}

/// Internal model for tracking image replacement state.
class _ImageReplacementState {
  final String? error;
  final String filename;
  final bool isSaving;

  const _ImageReplacementState({
    this.error,
    required this.filename,
    this.isSaving = false,
  });
}

/// Banner widget for displaying save errors.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PortfolioTheme.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PortfolioTheme.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: PortfolioTheme.error, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: PortfolioTheme.error, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
