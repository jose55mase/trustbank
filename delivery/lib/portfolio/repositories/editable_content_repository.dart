import '../models/editable_content.dart';

/// Abstract repository interface for editable content query and update operations.
abstract class EditableContentRepository {
  /// Returns all editable content items.
  Future<List<EditableContent>> getAllContent();

  /// Returns editable content items filtered by section.
  Future<List<EditableContent>> getContentBySection(String section);

  /// Updates an existing editable content item.
  Future<void> updateContent(EditableContent content);

  /// Watches editable content items for a given section as a reactive stream.
  Stream<List<EditableContent>> watchContentBySection(String section);
}
