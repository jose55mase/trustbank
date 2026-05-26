import '../models/portfolio_project.dart';

/// Abstract repository interface for portfolio project CRUD and query operations.
abstract class PortfolioProjectRepository {
  /// Returns all projects ordered by creation date (newest first).
  Future<List<PortfolioProject>> getAllProjects();

  /// Returns only projects marked as featured.
  Future<List<PortfolioProject>> getFeaturedProjects();

  /// Returns a single project by its ID, or null if not found.
  Future<PortfolioProject?> getProjectById(String id);

  /// Creates a new project in the data store.
  Future<void> createProject(PortfolioProject project);

  /// Updates an existing project in the data store.
  Future<void> updateProject(PortfolioProject project);

  /// Deletes a project by its ID.
  Future<void> deleteProject(String id);

  /// Watches all projects as a reactive stream.
  Stream<List<PortfolioProject>> watchAllProjects();

  /// Watches only featured projects as a reactive stream.
  Stream<List<PortfolioProject>> watchFeaturedProjects();
}
