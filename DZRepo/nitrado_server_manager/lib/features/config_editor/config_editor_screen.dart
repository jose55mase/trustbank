import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/models/file_entry.dart';
import '../../shared/widgets/nav_menu_button.dart';
import 'config_editor_notifier.dart';

/// Screen for browsing and editing server configuration files.
///
/// Two views:
/// - File list: shows available config files from the API (Req 5.1)
/// - Editor: shows file content with syntax highlighting (Req 5.2)
///
/// Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
class ConfigEditorScreen extends ConsumerStatefulWidget {
  const ConfigEditorScreen({super.key});

  @override
  ConsumerState<ConfigEditorScreen> createState() => _ConfigEditorScreenState();
}

class _ConfigEditorScreenState extends ConsumerState<ConfigEditorScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(configEditorNotifierProvider.notifier).fetchFiles();
    });
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(configEditorNotifierProvider);

    // Show SnackBar on success (Req 10.4).
    ref.listen<ConfigEditorState>(configEditorNotifierProvider, (prev, next) {
      if (next.successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.successMessage!),
            backgroundColor: Colors.green,
          ),
        );
        ref.read(configEditorNotifierProvider.notifier).clearMessages();
      }
    });

    final hasSelection = editorState.selectedFilePath != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(hasSelection
            ? _fileNameFromPath(editorState.selectedFilePath!)
            : 'Configuración'),
        leading: hasSelection
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  ref
                      .read(configEditorNotifierProvider.notifier)
                      .clearSelection();
                },
              )
            : NavMenuButton.maybeOf(context),
      ),
      body: hasSelection
          ? _EditorView(state: editorState)
          : _FileListView(state: editorState),
    );
  }

  String _fileNameFromPath(String path) {
    final parts = path.split('/');
    return parts.isNotEmpty ? parts.last : path;
  }
}

/// File list view showing available config files (Req 5.1).
class _FileListView extends ConsumerWidget {
  final ConfigEditorState state;
  const _FileListView({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.filesError != null && state.files.isEmpty) {
      return _ErrorView(
        message: state.filesError!,
        onRetry: () =>
            ref.read(configEditorNotifierProvider.notifier).fetchFiles(),
      );
    }

    if (state.isLoadingFiles && state.files.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.files.isEmpty) {
      return const Center(
        child: Text('No se encontraron archivos de configuración'),
      );
    }

    return RefreshIndicator(
      onRefresh: () =>
          ref.read(configEditorNotifierProvider.notifier).fetchFiles(),
      child: ListView.builder(
        itemCount: state.files.length,
        itemBuilder: (context, index) {
          final file = state.files[index];
          return _FileEntryTile(file: file);
        },
      ),
    );
  }
}

/// Tile for a single file entry.
class _FileEntryTile extends ConsumerWidget {
  final FileEntry file;
  const _FileEntryTile({required this.file});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDir = file.type == 'dir';
    return ListTile(
      leading: Icon(
        isDir ? Icons.folder : _iconForFile(file.name),
        color: isDir ? Colors.amber : null,
      ),
      title: Text(file.name),
      subtitle: file.size != null ? Text('${file.size} bytes') : null,
      trailing: isDir ? const Icon(Icons.chevron_right) : null,
      onTap: () {
        if (isDir) {
          ref
              .read(configEditorNotifierProvider.notifier)
              .fetchFiles(file.path);
        } else {
          ref
              .read(configEditorNotifierProvider.notifier)
              .selectFile(file.path);
        }
      },
    );
  }

  IconData _iconForFile(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.xml')) return Icons.code;
    if (lower.endsWith('.json')) return Icons.data_object;
    return Icons.insert_drive_file;
  }
}

/// Editor view with syntax highlighting and save button (Req 5.2, 5.3, 5.4, 5.5, 5.6).
class _EditorView extends ConsumerStatefulWidget {
  final ConfigEditorState state;
  const _EditorView({required this.state});

  @override
  ConsumerState<_EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<_EditorView> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.state.fileContent ?? '');
  }

  @override
  void didUpdateWidget(covariant _EditorView oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update controller when content is freshly loaded.
    if (widget.state.fileContent != oldWidget.state.fileContent &&
        widget.state.fileContent != null &&
        !widget.state.isLoadingContent) {
      _controller.text = widget.state.fileContent!;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state.isLoadingContent) {
      return const Center(child: CircularProgressIndicator());
    }

    if (widget.state.contentError != null) {
      return _ErrorView(
        message: widget.state.contentError!,
        onRetry: () {
          final path = widget.state.selectedFilePath;
          if (path != null) {
            ref
                .read(configEditorNotifierProvider.notifier)
                .selectFile(path);
          }
        },
      );
    }

    final fileType = widget.state.selectedFilePath != null
        ? fileTypeFromPath(widget.state.selectedFilePath!)
        : ConfigFileType.unknown;

    return Column(
      children: [
        // Validation error banner (Req 5.4, 5.5, 5.6).
        if (widget.state.validationError != null)
          MaterialBanner(
            content: Text(widget.state.validationError!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            leading: Icon(Icons.error,
                color: Theme.of(context).colorScheme.error),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(configEditorNotifierProvider.notifier)
                    .clearMessages(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        if (widget.state.uploadError != null)
          MaterialBanner(
            content: Text(widget.state.uploadError!),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            leading: Icon(Icons.cloud_off,
                color: Theme.of(context).colorScheme.error),
            actions: [
              TextButton(
                onPressed: () => ref
                    .read(configEditorNotifierProvider.notifier)
                    .clearMessages(),
                child: const Text('Cerrar'),
              ),
            ],
          ),
        // Editor area.
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 13,
                color: _textColorForType(fileType, context),
              ),
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Contenido del archivo...',
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceContainerLowest,
              ),
            ),
          ),
        ),
        // Save button (Req 5.3).
        Padding(
          padding: const EdgeInsets.all(12.0),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.state.isUploading
                  ? null
                  : () => ref
                      .read(configEditorNotifierProvider.notifier)
                      .saveFile(_controller.text),
              icon: widget.state.isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: const Text('Guardar'),
            ),
          ),
        ),
      ],
    );
  }

  Color _textColorForType(ConfigFileType type, BuildContext context) {
    switch (type) {
      case ConfigFileType.xml:
        return Colors.teal.shade700;
      case ConfigFileType.json:
        return Colors.indigo.shade700;
      case ConfigFileType.unknown:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
}

/// Error view with retry button.
class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off,
              size: 64, color: Theme.of(context).colorScheme.error),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }
}
