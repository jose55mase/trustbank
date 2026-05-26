import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/editable_content.dart';
import '../providers/portfolio_providers.dart';
import '../theme/portfolio_theme.dart';

/// Panel for managing editable content items organized by section.
///
/// Features:
/// - Lists all editable content grouped by section (hero, about, footer, etc.)
/// - Inline text/title editing with save functionality
/// - Image replacement with format/size validation (PNG/JPG/WebP, ≤5MB)
/// - Changes reflect in public page within 5 seconds via StreamProvider
/// - Validates required fields are not empty/whitespace-only
/// - Shows error message and preserves edited content on save failure
///
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.6, 6.7
class ContentEditorPanel extends ConsumerStatefulWidget {
  /// The list of sections to display. If null, defaults to common sections.
  final List<String>? sections;

  const ContentEditorPanel({
    super.key,
    this.sections,
  });

  /// Default sections displayed when none are specified.
  static const defaultSections = ['hero', 'about', 'footer'];

  /// Validates a text/title content value.
  /// Returns null if valid, or an error message string.
  static String? validateContentValue(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'El contenido es requerido';
    }
    return null;
  }

  /// Validates an image file for replacement.
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
  ConsumerState<ContentEditorPanel> createState() =>
      ContentEditorPanelState();
}

class ContentEditorPanelState extends ConsumerState<ContentEditorPanel> {
  /// Tracks the currently editing content item id.
  String? _editingId;

  /// Controller for the text being edited.
  final TextEditingController _editController = TextEditingController();

  /// Validation error for the currently editing item.
  String? _editError;

  /// Whether a save operation is in progress.
  bool _isSaving = false;

  /// Global save error message (shown as banner or snackbar).
  String? _saveError;

  /// Tracks image replacement state per content id.
  final Map<String, _ImageReplacement> _imageReplacements = {};

  List<String> get _sections =>
      widget.sections ?? ContentEditorPanel.defaultSections;

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  /// Starts editing a text/title content item.
  void startEditing(EditableContent content) {
    setState(() {
      _editingId = content.id;
      _editController.text = content.value;
      _editError = null;
      _saveError = null;
    });
  }

  /// Cancels the current editing operation.
  void cancelEditing() {
    setState(() {
      _editingId = null;
      _editController.clear();
      _editError = null;
    });
  }

  /// Saves the currently edited text/title content.
  Future<void> saveContent(EditableContent content) async {
    final newValue = _editController.text;

    // Validate
    final error = ContentEditorPanel.validateContentValue(newValue);
    if (error != null) {
      setState(() {
        _editError = error;
      });
      return;
    }

    setState(() {
      _isSaving = true;
      _editError = null;
      _saveError = null;
    });

    try {
      final contentRepo = ref.read(contentRepositoryProvider);
      final updatedContent = content.copyWith(
        value: newValue.trim(),
        updatedAt: DateTime.now(),
      );
      await contentRepo.updateContent(updatedContent);

      if (mounted) {
        setState(() {
          _isSaving = false;
          _editingId = null;
          _editController.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError =
              'No se pudo guardar el cambio. Intente de nuevo.';
        });
      }
    }
  }

  /// Replaces an image content item with new bytes.
  /// Called programmatically (e.g., from a file picker or tests).
  Future<void> replaceImage(
    EditableContent content,
    Uint8List bytes,
    String filename,
  ) async {
    // Validate format and size
    final error = ContentEditorPanel.validateImageFile(bytes, filename);
    if (error != null) {
      setState(() {
        _imageReplacements[content.id] = _ImageReplacement(
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
        _imageReplacements[content.id] = _ImageReplacement(
          error: 'Formato no soportado. Use PNG, JPG o WebP (máx 5 MB)',
          filename: filename,
        );
      });
      return;
    }

    setState(() {
      _imageReplacements[content.id] = _ImageReplacement(
        filename: filename,
        isSaving: true,
      );
      _saveError = null;
    });

    try {
      // Upload the new image
      final url = await imageRepo.uploadImage(bytes, filename);

      // Update the content with the new URL
      final contentRepo = ref.read(contentRepositoryProvider);
      final updatedContent = content.copyWith(
        value: url,
        updatedAt: DateTime.now(),
      );
      await contentRepo.updateContent(updatedContent);

      if (mounted) {
        setState(() {
          _imageReplacements.remove(content.id);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _imageReplacements[content.id] = _ImageReplacement(
            filename: filename,
            error: 'No se pudo guardar el cambio. Intente de nuevo.',
          );
          _saveError =
              'No se pudo guardar el cambio. Intente de nuevo.';
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
          title: const Text('Editar Contenido'),
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
                  ..._sections.map(_buildSection),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String section) {
    final contentAsync = ref.watch(editableContentProvider(section));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            _sectionTitle(section),
            style: TextStyle(
              color: PortfolioTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        // Content items
        contentAsync.when(
          data: (items) {
            if (items.isEmpty) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  'No hay contenido en esta sección',
                  style: TextStyle(
                    color: PortfolioTheme.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              );
            }
            return Column(
              children: items.map(_buildContentItem).toList(),
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'Error al cargar contenido: $error',
              style: TextStyle(color: PortfolioTheme.error),
            ),
          ),
        ),
        Divider(color: PortfolioTheme.divider),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildContentItem(EditableContent content) {
    switch (content.type) {
      case ContentType.text:
      case ContentType.title:
        return _buildTextItem(content);
      case ContentType.image:
        return _buildImageItem(content);
    }
  }

  Widget _buildTextItem(EditableContent content) {
    final isEditing = _editingId == content.id;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: PortfolioTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Icon(
                  content.type == ContentType.title
                      ? Icons.title
                      : Icons.text_fields,
                  size: 18,
                  color: PortfolioTheme.textSecondary,
                ),
                const SizedBox(width: 8),
                Text(
                  '${content.section} / ${content.key}',
                  style: TextStyle(
                    color: PortfolioTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const Spacer(),
                if (!isEditing)
                  IconButton(
                    icon: Icon(Icons.edit,
                        size: 18, color: PortfolioTheme.primaryBlue),
                    onPressed: () => startEditing(content),
                    tooltip: 'Editar',
                  ),
              ],
            ),
            const SizedBox(height: 8),
            // Content display or edit field
            if (isEditing) ...[
              TextField(
                controller: _editController,
                maxLines: content.type == ContentType.title ? 1 : 3,
                decoration: InputDecoration(
                  hintText: 'Ingrese el contenido',
                  errorText: _editError,
                  filled: true,
                  fillColor: PortfolioTheme.surfaceVariant,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: PortfolioTheme.divider),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : cancelEditing,
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _isSaving ? null : () => saveContent(content),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PortfolioTheme.primaryBlue,
                      foregroundColor: PortfolioTheme.accentBlack,
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar'),
                  ),
                ],
              ),
            ] else
              Text(
                content.value,
                style: TextStyle(
                  color: PortfolioTheme.textPrimary,
                  fontSize: content.type == ContentType.title ? 16 : 14,
                  fontWeight: content.type == ContentType.title
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageItem(EditableContent content) {
    final replacement = _imageReplacements[content.id];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: PortfolioTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label row
            Row(
              children: [
                Icon(Icons.image, size: 18, color: PortfolioTheme.textSecondary),
                const SizedBox(width: 8),
                Text(
                  '${content.section} / ${content.key}',
                  style: TextStyle(
                    color: PortfolioTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Current image preview
            if (content.value.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  content.value,
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
                      child: Icon(Icons.broken_image,
                          color: PortfolioTheme.textHint),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Replace button and status
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: replacement?.isSaving == true ? null : () {},
                  icon: const Icon(Icons.upload_file, size: 18),
                  label: const Text('Reemplazar'),
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
            // Error message for image replacement
            if (replacement?.error != null) ...[
              const SizedBox(height: 8),
              Text(
                replacement!.error!,
                style: TextStyle(
                  color: PortfolioTheme.error,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _sectionTitle(String section) {
    switch (section.toLowerCase()) {
      case 'hero':
        return 'Hero';
      case 'about':
        return 'Acerca de';
      case 'footer':
        return 'Pie de página';
      default:
        return section[0].toUpperCase() + section.substring(1);
    }
  }
}

/// Internal model for tracking image replacement state.
class _ImageReplacement {
  final String? error;
  final String filename;
  final bool isSaving;

  const _ImageReplacement({
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
