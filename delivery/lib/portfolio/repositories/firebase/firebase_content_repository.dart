import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/editable_content.dart';
import '../editable_content_repository.dart';

/// Firebase Firestore implementation of [EditableContentRepository].
///
/// Uses the `editable_content/` collection in Firestore.
class FirebaseContentRepository implements EditableContentRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'editable_content';

  FirebaseContentRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _contentRef =>
      _firestore.collection(_collection);

  @override
  Future<List<EditableContent>> getAllContent() async {
    final snapshot = await _contentRef.orderBy('section').get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<List<EditableContent>> getContentBySection(String section) async {
    final snapshot =
        await _contentRef.where('section', isEqualTo: section).get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<void> updateContent(EditableContent content) async {
    await _contentRef.doc(content.id).update(_toDocument(content));
  }

  @override
  Stream<List<EditableContent>> watchContentBySection(String section) {
    return _contentRef
        .where('section', isEqualTo: section)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  EditableContent _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return EditableContent(
      id: doc.id,
      section: data['section'] as String,
      key: data['key'] as String,
      value: data['value'] as String,
      type: ContentType.values.byName(data['type'] as String),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toDocument(EditableContent content) {
    return {
      'section': content.section,
      'key': content.key,
      'value': content.value,
      'type': content.type.name,
      'updatedAt': Timestamp.fromDate(content.updatedAt),
    };
  }
}
