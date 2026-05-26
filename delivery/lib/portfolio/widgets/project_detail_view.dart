import 'package:flutter/material.dart';

import '../models/portfolio_project.dart';
import '../theme/portfolio_theme.dart';
import 'portfolio_responsive_layout.dart';

/// Displays the full detail view of a portfolio project.
///
/// Shows:
/// - Full project title (no truncation)
/// - Full untruncated description
/// - Main image prominently displayed
/// - Additional images in a responsive gallery layout
/// - Technologies as chips/tags
/// - External link as a clickable button (if present)
///
/// Uses [PortfolioResponsiveLayout] for breakpoint-aware layout and
/// [PortfolioTheme] colors for consistent styling.
///
/// Requirements: 3.3
class ProjectDetailView extends StatelessWidget {
  const ProjectDetailView({
    super.key,
    required this.project,
    this.onExternalLinkTap,
    this.onBackPressed,
  });

  /// The project to display in detail.
  final PortfolioProject project;

  /// Callback when the external link is tapped.
  /// If null, defaults to no-op (useful for testing without url_launcher).
  final VoidCallback? onExternalLinkTap;

  /// Callback when the back button is pressed.
  final VoidCallback? onBackPressed;

  @override
  Widget build(BuildContext context) {
    return PortfolioResponsiveLayout(
      builder: (context, layoutData) {
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button
              if (onBackPressed != null)
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 8),
                  child: TextButton.icon(
                    onPressed: onBackPressed,
                    icon: Icon(
                      Icons.arrow_back,
                      color: PortfolioTheme.accentBlack,
                    ),
                    label: Text(
                      'Back',
                      style: TextStyle(color: PortfolioTheme.accentBlack),
                    ),
                  ),
                ),

              // Main image
              _buildMainImage(layoutData),

              const SizedBox(height: 24),

              // Title
              Text(
                project.title,
                style: TextStyle(
                  color: PortfolioTheme.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 16),

              // Technologies
              if (project.technologies.isNotEmpty) ...[
                _buildTechnologies(),
                const SizedBox(height: 16),
              ],

              // Description
              Text(
                project.description,
                style: TextStyle(
                  color: PortfolioTheme.textSecondary,
                  fontSize: 16,
                  height: 1.6,
                ),
              ),

              const SizedBox(height: 24),

              // External link
              if (project.externalLink != null &&
                  project.externalLink!.isNotEmpty)
                _buildExternalLink(),

              // Additional images gallery
              if (project.additionalImageUrls.isNotEmpty) ...[
                const SizedBox(height: 32),
                _buildImageGallery(layoutData),
              ],

              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  /// Builds the main image with responsive aspect ratio and fallback.
  Widget _buildMainImage(PortfolioLayoutData layoutData) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: layoutData.breakpoint.isMobile ? 4 / 3 : 16 / 9,
        child: Image.network(
          project.mainImageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            return _buildImagePlaceholder(project.title);
          },
        ),
      ),
    );
  }

  /// Builds the technologies section as a wrap of chips.
  Widget _buildTechnologies() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: project.technologies.map((tech) {
        return Chip(
          label: Text(
            tech,
            style: TextStyle(
              color: PortfolioTheme.accentBlack,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          backgroundColor: PortfolioTheme.primaryBlue.withOpacity(0.3),
          side: BorderSide(
            color: PortfolioTheme.primaryBlue,
            width: 1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        );
      }).toList(),
    );
  }

  /// Builds the external link button.
  Widget _buildExternalLink() {
    return ElevatedButton.icon(
      onPressed: onExternalLinkTap,
      icon: Icon(
        Icons.open_in_new,
        color: PortfolioTheme.accentBlack,
        size: 20,
      ),
      label: Text(
        'View Project',
        style: TextStyle(
          color: PortfolioTheme.accentBlack,
          fontWeight: FontWeight.w600,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: PortfolioTheme.primaryBlue,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  /// Builds the responsive image gallery for additional images.
  Widget _buildImageGallery(PortfolioLayoutData layoutData) {
    final crossAxisCount = switch (layoutData.breakpoint) {
      PortfolioBreakpoint.mobile => 1,
      PortfolioBreakpoint.tablet => 2,
      PortfolioBreakpoint.desktop => 3,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gallery',
          style: TextStyle(
            color: PortfolioTheme.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 4 / 3,
          ),
          itemCount: project.additionalImageUrls.length,
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                project.additionalImageUrls[index],
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return _buildImagePlaceholder(
                    'Image ${index + 1}',
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// Builds a fallback placeholder for images that fail to load.
  Widget _buildImagePlaceholder(String label) {
    return Container(
      color: PortfolioTheme.primaryBlue,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
