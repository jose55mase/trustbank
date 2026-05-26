import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/editable_content.dart';
import '../models/portfolio_auth_state.dart';
import '../models/portfolio_project.dart';
import '../repositories/editable_content_repository.dart';
import '../repositories/firebase/firebase_content_repository.dart';
import '../repositories/firebase/firebase_image_storage_repository.dart';
import '../repositories/firebase/firebase_project_repository.dart';
import '../repositories/image_storage_repository.dart';
import '../repositories/portfolio_project_repository.dart';
import 'portfolio_auth_notifier.dart';

// ---------------------------------------------------------------------------
// Firebase Auth provider (used by PortfolioAuthNotifier)
// ---------------------------------------------------------------------------

/// Provides the FirebaseAuth instance for portfolio authentication.
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

// ---------------------------------------------------------------------------
// Repository providers
// ---------------------------------------------------------------------------

/// Provides the [PortfolioProjectRepository] implementation.
final projectRepositoryProvider = Provider<PortfolioProjectRepository>((ref) {
  return FirebaseProjectRepository();
});

/// Provides the [EditableContentRepository] implementation.
final contentRepositoryProvider = Provider<EditableContentRepository>((ref) {
  return FirebaseContentRepository();
});

/// Provides the [ImageStorageRepository] implementation.
final imageStorageProvider = Provider<ImageStorageRepository>((ref) {
  return FirebaseImageStorageRepository();
});

// ---------------------------------------------------------------------------
// Stream providers (reactive data)
// ---------------------------------------------------------------------------

/// Watches all portfolio projects as a reactive stream.
///
/// Validates: Requirements 3.1
final allProjectsProvider = StreamProvider<List<PortfolioProject>>((ref) {
  return ref.watch(projectRepositoryProvider).watchAllProjects();
});

/// Watches only featured portfolio projects as a reactive stream.
///
/// Validates: Requirements 2.1
final featuredProjectsProvider = StreamProvider<List<PortfolioProject>>((ref) {
  return ref.watch(projectRepositoryProvider).watchFeaturedProjects();
});

/// Watches editable content items for a given section as a reactive stream.
///
/// Validates: Requirements 6.1
final editableContentProvider =
    StreamProvider.family<List<EditableContent>, String>((ref, section) {
  return ref.watch(contentRepositoryProvider).watchContentBySection(section);
});

// ---------------------------------------------------------------------------
// Authentication provider
// ---------------------------------------------------------------------------

/// Manages portfolio admin authentication state.
///
/// Validates: Requirements 4.1
final portfolioAuthProvider =
    StateNotifierProvider<PortfolioAuthNotifier, PortfolioAuthState>((ref) {
  return PortfolioAuthNotifier(ref.watch(firebaseAuthProvider));
});
