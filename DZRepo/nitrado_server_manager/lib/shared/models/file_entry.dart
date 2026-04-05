/// Represents a file or directory entry on the server.
class FileEntry {
  final String name;
  final String path;
  final String type; // "file" or "dir"
  final int? size;

  const FileEntry({
    required this.name,
    required this.path,
    required this.type,
    this.size,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FileEntry &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path &&
          type == other.type &&
          size == other.size;

  @override
  int get hashCode => Object.hash(name, path, type, size);

  @override
  String toString() =>
      'FileEntry(name: $name, path: $path, type: $type, size: $size)';
}
