import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/portfolio_project.dart';
import '../portfolio_project_repository.dart';

/// Firebase Firestore implementation of [PortfolioProjectRepository].
///
/// Uses the `portfolio_projects/` collection in Firestore.
class FirebaseProjectRepository implements PortfolioProjectRepository {
  final FirebaseFirestore _firestore;

  static const String _collection = 'portfolio_projects';

  FirebaseProjectRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _projectsRef =>
      _firestore.collection(_collection);

  @override
  Future<List<PortfolioProject>> getAllProjects() async {
    final snapshot =
        await _projectsRef.orderBy('createdAt', descending: true).get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<List<PortfolioProject>> getFeaturedProjects() async {
    final snapshot = await _projectsRef
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs.map(_fromDocument).toList();
  }

  @override
  Future<PortfolioProject?> getProjectById(String id) async {
    final doc = await _projectsRef.doc(id).get();
    if (!doc.exists) return null;
    return _fromDocument(doc);
  }

  @override
  Future<void> createProject(PortfolioProject project) async {
    await _projectsRef.doc(project.id).set(_toDocument(project));
  }

  @override
  Future<void> updateProject(PortfolioProject project) async {
    await _projectsRef.doc(project.id).update(_toDocument(project));
  }

  @override
  Future<void> deleteProject(String id) async {
    await _projectsRef.doc(id).delete();
  }

  @override
  Stream<List<PortfolioProject>> watchAllProjects() {
    return _projectsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  @override
  Stream<List<PortfolioProject>> watchFeaturedProjects() {
    return _projectsRef
        .where('isFeatured', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDocument).toList());
  }

  PortfolioProject _fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return PortfolioProject(
      id: doc.id,
      title: data['title'] as String,
      description: data['description'] as String,
      mainImageUrl: data['mainImageUrl'] as String,
      additionalImageUrls: (data['additionalImageUrls'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      externalLink: data['externalLink'] as String?,
      technologies: (data['technologies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      isFeatured: data['isFeatured'] as bool? ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> _toDocument(PortfolioProject project) {
    return {
      'title': project.title,
      'description': project.description,
      'mainImageUrl': project.mainImageUrl,
      'additionalImageUrls': project.additionalImageUrls,
      'externalLink': project.externalLink,
      'technologies': project.technologies,
      'isFeatured': project.isFeatured,
      'createdAt': Timestamp.fromDate(project.createdAt),
      'updatedAt': Timestamp.fromDate(project.updatedAt),
    };
  }
}
