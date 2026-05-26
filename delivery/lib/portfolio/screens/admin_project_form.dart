import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/portfolio_project.dart';
import '../providers/portfolio_providers.dart';
import '../theme/portfolio_theme.dart';

/// Form widget for creating and editing portfolio projects.
///
/// Features:
/// - Title field (required, max 100 chars)
/// - Description field (required, max 500 chars)
/// - Main image upload (required, PNG/JPG/WebP, max 5MB)
/// - Additional images (optional, max 5, PNG/JPG/WebP, max 5MB each)
/// - External link (optional)
/// - Technologies (optional, comma-separated input)
/// - isFeatured toggle
///
/// In edit mode, all fields are pre-filled with existing project data.
/// On validation failure, inline error messages are shown and other field values are preserved.
/// On save success, the project appears in the catalog via StreamProvider (no manual reload).
///
/// Validates: Requirements 5.1, 5.2, 5.3, 5.5, 5.6
class AdminProjectForm extends ConsumerStatefulWidget {
  /// If provided, the form operates in edit mode with pre-filled data.
  final PortfolioProject? existingProject;

  /// Callback invoked after a successful save.
  final VoidCallback? onSaveSuccess;

  const AdminProjectForm({
    super.key,
    this.existingProject,
    this.onSaveSuccess,
  });

  /// Validates the title field.
  static String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El título es obligatorio';
    }
    if (value.length > 100) {
      return 'El título no puede exceder 100 caracteres';
    }
    return null;
  }

  /// Validates the description field.
  static String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'La descripción es obligatoria';
    }
    if (value.length > 500) {
      return 'La descripción no puede exceder 500 caracteres';
    }
    return null;
  }

  /// Validates an image file (format and size).
  /// Returns null if valid, or an error message string.
  static String? validateImageFile(Uint8List bytes, String filename) {
    // Check file extension
    final ext = filename.split('.').last.toLowerCase();
    const allowedExtensions = ['png', 'jpg', 'jpeg', 'webp'];
    if (!allowedExtensions.contains(ext)) {
      return 'Formato no soportado. Use PNG, JPG o WebP';
    }
    // Check file size (max 5MB)
    const maxSize = 5 * 1024 * 1024; // 5 MB
    if (bytes.length > maxSize) {
      return 'La imagen no puede exceder 5 MB';
    }
    return null;
  }

  @override
  ConsumerState<AdminProjectForm> createState() => _AdminProjectFormState();
}

class _AdminProjectFormState extends ConsumerState<AdminProjectForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _externalLinkController;
  late final TextEditingController _technologiesController;

  bool _isFeatured = false;
  bool _isSaving = false;
  String? _saveError;

  // Image state
  _ImageSelection? _mainImage;
  final List<_ImageSelection> _additionalImages = [];
  String? _mainImageError;
  String? _additionalImagesError;

  bool get _isEditMode => widget.existingProject != null;

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;

    _titleController = TextEditingController(text: project?.title ?? '');
    _descriptionController =
        TextEditingController(text: project?.description ?? '');
    _externalLinkController =
        TextEditingController(text: project?.externalLink ?? '');
    _technologiesController =
        TextEditingController(text: project?.technologies.join(', ') ?? '');
    _isFeatured = project?.isFeatured ?? false;

    if (project != null) {
      // Pre-fill main image as existing URL
      _mainImage = _ImageSelection(
        url: project.mainImageUrl,
        filename: _filenameFromUrl(project.mainImageUrl),
      );
      // Pre-fill additional images as existing URLs
      for (final url in project.additionalImageUrls) {
        _additionalImages.add(_ImageSelection(
          url: url,
          filename: _filenameFromUrl(url),
        ));
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _externalLinkController.dispose();
    _technologiesController.dispose();
    super.dispose();
  }

  String _filenameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) return 'image';
    final segments = uri.pathSegments;
    return segments.isNotEmpty ? segments.last : 'image';
  }

  Future<void> _pickMainImage() async {
    // In a real app, this would use file_picker or image_picker.
    // For testability, we expose a method that accepts bytes + filename.
    // The actual picker integration is handled by the platform layer.
    // This is a placeholder that subclasses/tests can override.
  }

  /// Sets the main image from bytes and filename (used by tests and platform picker).
  Future<void> setMainImage(Uint8List bytes, String filename) async {
    final error = AdminProjectForm.validateImageFile(bytes, filename);
    if (error != null) {
      setState(() {
        _mainImageError = error;
      });
      return;
    }

    // Also validate via repository if available
    final imageRepo = ref.read(imageStorageProvider);
    final isValid = await imageRepo.validateImage(bytes, filename);
    if (!isValid) {
      setState(() {
        _mainImageError = 'Formato no soportado. Use PNG, JPG o WebP (máx 5 MB)';
      });
      return;
    }

    setState(() {
      _mainImage = _ImageSelection(bytes: bytes, filename: filename);
      _mainImageError = null;
    });
  }

  /// Adds an additional image from bytes and filename.
  Future<void> addAdditionalImage(Uint8List bytes, String filename) async {
    if (_additionalImages.length >= 5) {
      setState(() {
        _additionalImagesError = 'Máximo 5 imágenes adicionales permitidas';
      });
      return;
    }

    final error = AdminProjectForm.validateImageFile(bytes, filename);
    if (error != null) {
      setState(() {
        _additionalImagesError = error;
      });
      return;
    }

    final imageRepo = ref.read(imageStorageProvider);
    final isValid = await imageRepo.validateImage(bytes, filename);
    if (!isValid) {
      setState(() {
        _additionalImagesError =
            'Formato no soportado. Use PNG, JPG o WebP (máx 5 MB)';
      });
      return;
    }

    setState(() {
      _additionalImages.add(_ImageSelection(bytes: bytes, filename: filename));
      _additionalImagesError = null;
    });
  }

  /// Removes an additional image at the given index.
  void removeAdditionalImage(int index) {
    if (index >= 0 && index < _additionalImages.length) {
      setState(() {
        _additionalImages.removeAt(index);
        _additionalImagesError = null;
      });
    }
  }

  Future<void> _handleSave() async {
    // Validate form fields
    final isFormValid = _formKey.currentState?.validate() ?? false;

    // Validate main image
    bool hasMainImageError = false;
    if (_mainImage == null) {
      setState(() {
        _mainImageError = 'La imagen principal es obligatoria';
      });
      hasMainImageError = true;
    }

    if (!isFormValid || hasMainImageError) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveError = null;
    });

    try {
      final imageRepo = ref.read(imageStorageProvider);
      final projectRepo = ref.read(projectRepositoryProvider);

      // Upload main image if it's new (has bytes)
      String mainImageUrl;
      if (_mainImage!.bytes != null) {
        mainImageUrl =
            await imageRepo.uploadImage(_mainImage!.bytes!, _mainImage!.filename);
      } else {
        mainImageUrl = _mainImage!.url!;
      }

      // Upload additional images (only new ones with bytes)
      final List<String> additionalUrls = [];
      for (final img in _additionalImages) {
        if (img.bytes != null) {
          final url = await imageRepo.uploadImage(img.bytes!, img.filename);
          additionalUrls.add(url);
        } else {
          additionalUrls.add(img.url!);
        }
      }

      // Parse technologies
      final technologies = _technologiesController.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      final now = DateTime.now();

      if (_isEditMode) {
        final updatedProject = widget.existingProject!.copyWith(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          mainImageUrl: mainImageUrl,
          additionalImageUrls: additionalUrls,
          externalLink: _externalLinkController.text.trim().isEmpty
              ? null
              : _externalLinkController.text.trim(),
          technologies: technologies,
          isFeatured: _isFeatured,
          updatedAt: now,
        );
        await projectRepo.updateProject(updatedProject);
      } else {
        final newProject = PortfolioProject(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          mainImageUrl: mainImageUrl,
          additionalImageUrls: additionalUrls,
          externalLink: _externalLinkController.text.trim().isEmpty
              ? null
              : _externalLinkController.text.trim(),
          technologies: technologies,
          isFeatured: _isFeatured,
          createdAt: now,
          updatedAt: now,
        );
        await projectRepo.createProject(newProject);
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        widget.onSaveSuccess?.call();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError =
              'No se pudo completar la operación. Intente de nuevo.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: PortfolioTheme.lightTheme,
      child: Scaffold(
        backgroundColor: PortfolioTheme.background,
        appBar: AppBar(
          title: Text(_isEditMode ? 'Editar Proyecto' : 'Nuevo Proyecto'),
          backgroundColor: PortfolioTheme.surface,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Save error banner
                    if (_saveError != null) ...[
                      _ErrorBanner(message: _saveError!),
                      const SizedBox(height: 16),
                    ],

                    // Title field
                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título *',
                        hintText: 'Nombre del proyecto',
                        counterText: '',
                      ),
                      maxLength: 100,
                      validator: AdminProjectForm.validateTitle,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Description field
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción *',
                        hintText: 'Descripción del proyecto',
                        counterText: '',
                      ),
                      maxLength: 500,
                      maxLines: 4,
                      validator: AdminProjectForm.validateDescription,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Main image section
                    _buildImageSection(),
                    const SizedBox(height: 16),

                    // Additional images section
                    _buildAdditionalImagesSection(),
                    const SizedBox(height: 16),

                    // External link field
                    TextFormField(
                      controller: _externalLinkController,
                      decoration: const InputDecoration(
                        labelText: 'Enlace externo',
                        hintText: 'https://ejemplo.com',
                        prefixIcon: Icon(Icons.link),
                      ),
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: 16),

                    // Technologies field
                    TextFormField(
                      controller: _technologiesController,
                      decoration: const InputDecoration(
                        labelText: 'Tecnologías',
                        hintText: 'Flutter, Dart, Firebase (separadas por coma)',
                        prefixIcon: Icon(Icons.code),
                      ),
                      textInputAction: TextInputAction.done,
                    ),
                    const SizedBox(height: 16),

                    // isFeatured toggle
                    SwitchListTile(
                      title: Text(
                        'Proyecto destacado',
                        style: TextStyle(color: PortfolioTheme.textPrimary),
                      ),
                      subtitle: Text(
                        'Aparecerá en el carrusel de la página principal',
                        style: TextStyle(color: PortfolioTheme.textSecondary),
                      ),
                      value: _isFeatured,
                      onChanged: (value) {
                        setState(() {
                          _isFeatured = value;
                        });
                      },
                      activeColor: PortfolioTheme.primaryBlue,
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    SizedBox(
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _handleSave,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PortfolioTheme.primaryBlue,
                          foregroundColor: PortfolioTheme.accentBlack,
                          disabledBackgroundColor:
                              PortfolioTheme.primaryBlue.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: PortfolioTheme.accentBlack,
                                ),
                              )
                            : Text(
                                _isEditMode
                                    ? 'Guardar cambios'
                                    : 'Crear proyecto',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imagen principal *',
          style: TextStyle(
            color: PortfolioTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (_mainImage != null)
          _ImageChip(
            label: _mainImage!.filename,
            onRemove: () {
              setState(() {
                _mainImage = null;
              });
            },
          )
        else
          OutlinedButton.icon(
            onPressed: _pickMainImage,
            icon: const Icon(Icons.upload_file),
            label: const Text('Seleccionar imagen'),
          ),
        if (_mainImageError != null) ...[
          const SizedBox(height: 4),
          Text(
            _mainImageError!,
            style: TextStyle(
              color: PortfolioTheme.error,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalImagesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes adicionales (máx. 5)',
          style: TextStyle(
            color: PortfolioTheme.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (int i = 0; i < _additionalImages.length; i++)
              _ImageChip(
                label: _additionalImages[i].filename,
                onRemove: () => removeAdditionalImage(i),
              ),
            if (_additionalImages.length < 5)
              OutlinedButton.icon(
                onPressed: () {
                  // Platform picker integration point
                },
                icon: const Icon(Icons.add_photo_alternate),
                label: const Text('Agregar'),
              ),
          ],
        ),
        if (_additionalImagesError != null) ...[
          const SizedBox(height: 4),
          Text(
            _additionalImagesError!,
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

/// Internal model representing an image selection (either new bytes or existing URL).
class _ImageSelection {
  final Uint8List? bytes;
  final String filename;
  final String? url;

  _ImageSelection({this.bytes, required this.filename, this.url});
}

/// Chip widget showing a selected image filename with a remove button.
class _ImageChip extends StatelessWidget {
  final String label;
  final VoidCallback onRemove;

  const _ImageChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: PortfolioTheme.textPrimary, fontSize: 12),
      ),
      deleteIcon: Icon(Icons.close, size: 16, color: PortfolioTheme.error),
      onDeleted: onRemove,
      backgroundColor: PortfolioTheme.surfaceVariant,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }
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
