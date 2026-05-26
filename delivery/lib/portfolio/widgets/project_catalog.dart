import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/portfolio_project.dart';
import '../theme/portfolio_theme.dart';
import 'interactive_carousel.dart';
import 'portfolio_responsive_layout.dart';

/// Displays all portfolio projects in a responsive grid layout.
///
/// - Single column on mobile (<768px)
/// - Multi-column grid on tablet/desktop (≥768px)
/// - Shows title, truncated description (max 150 chars), and main image
/// - Empty state message when no projects exist
/// - Image fallback placeholder on load failure
/// - Navigates to project detail on selection
///
/// Requirements: 3.1, 3.2, 3.4, 3.5, 3.6, 3.7
class ProjectCatalog extends StatelessWidget {
  const ProjectCatalog({
    super.key,
    required this.projects,
    this.onProjectSelected,
  });

  /// All projects to display in the catalog.
  final List<PortfolioProject> projects;

  /// Optional callback when a project is selected.
  /// If null, navigates to `/portfolio/project/:id` via GoRouter.
  final void Function(PortfolioProject project)? onProjectSelected;

  @override
  Widget build(BuildContext context) {
    if (projects.isEmpty) {
      return _buildEmptyState();
    }

    final breakpoint = context.portfolioBreakpoint;

    if (breakpoint.isMobile) {
      return _buildSingleColumnList(context);
    }

    return _buildMultiColumnGrid(context, breakpoint);
  }

  /// Builds the empty state message when no projects exist.
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open,
              size: 64,
              color: PortfolioTheme.textHint,
            ),
            const SizedBox(height: 16),
            Text(
              'No hay proyectos disponibles',
              style: TextStyle(
                color: PortfolioTheme.textSecondary,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a single-column list for mobile layout.
  Widget _buildSingleColumnList(BuildContext context) {
    return Column(
      children: projects
          .map((project) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: SizedBox(
                  height: 280,
                  child: _ProjectCard(
                    project: project,
                    onTap: () => _handleProjectTap(context, project),
                  ),
                ),
              ))
          .toList(),
    );
  }

  /// Builds a multi-column grid for tablet/desktop layout.
  Widget _buildMultiColumnGrid(
    BuildContext context,
    PortfolioBreakpoint breakpoint,
  ) {
    final crossAxisCount = breakpoint.isDesktop ? 3 : 2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: projects.length,
      itemBuilder: (context, index) {
        return _ProjectCard(
          project: projects[index],
          onTap: () => _handleProjectTap(context, projects[index]),
        );
      },
    );
  }

  /// Handles project selection — uses callback or GoRouter navigation.
  void _handleProjectTap(BuildContext context, PortfolioProject project) {
    if (onProjectSelected != null) {
      onProjectSelected!(project);
      return;
    }
    context.go('/portfolio/project/${project.id}');
  }
}

/// A card widget displaying a single project in the catalog.
class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.onTap,
  });

  final PortfolioProject project;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final truncatedDescription = truncateText(project.description, 150);

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: PortfolioTheme.cardColor,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image section
            Expanded(
              flex: 3,
              child: _buildProjectImage(),
            ),
            // Text content section
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      style: TextStyle(
                        color: PortfolioTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        truncatedDescription,
                        style: TextStyle(
                          color: PortfolioTheme.textSecondary,
                          fontSize: 13,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the project image with fallback placeholder on load failure.
  Widget _buildProjectImage() {
    return SizedBox(
      width: double.infinity,
      child: Image.network(
        project.mainImageUrl,
        fit: BoxFit.cover,
        width: double.infinity,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackPlaceholder();
        },
      ),
    );
  }

  /// Builds the fallback placeholder with primary blue background and title.
  Widget _buildFallbackPlaceholder() {
    return Container(
      color: PortfolioTheme.primaryBlue,
      width: double.infinity,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          project.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
