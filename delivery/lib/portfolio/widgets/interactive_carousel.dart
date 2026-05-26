import 'dart:async';

import 'package:flutter/material.dart';

import '../models/portfolio_project.dart';
import '../theme/portfolio_theme.dart';

/// Truncates [text] to [maxLength] characters, appending an ellipsis if needed.
///
/// If [text] length is within [maxLength], it is returned unchanged.
String truncateText(String text, int maxLength) {
  if (text.length <= maxLength) return text;
  return '${text.substring(0, maxLength - 1)}…';
}

/// Interactive carousel widget that displays featured portfolio projects.
///
/// Features:
/// - Displays only projects with `isFeatured == true` (filtered by provider)
/// - Swipe gestures and navigation buttons for manual advance
/// - Auto-advance every 5 seconds with timer reset on user interaction
/// - Cyclic navigation: after last item, return to first
/// - Title (max 60 chars), description (max 200 chars), and image with entry animations (≤400ms)
/// - Position indicator (current/total)
/// - Fallback placeholder when image fails to load
///
/// Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7
class InteractiveCarousel extends StatefulWidget {
  const InteractiveCarousel({
    super.key,
    required this.projects,
    this.autoAdvanceDuration = const Duration(seconds: 5),
    this.animationDuration = const Duration(milliseconds: 400),
    this.height = 400,
  });

  /// List of featured projects to display. Must contain at least 1 item.
  final List<PortfolioProject> projects;

  /// Duration of inactivity before auto-advancing to the next item.
  final Duration autoAdvanceDuration;

  /// Duration of entry animations for text and image.
  final Duration animationDuration;

  /// Height of the carousel widget.
  final double height;

  @override
  State<InteractiveCarousel> createState() => InteractiveCarouselState();
}

/// Visible for testing — exposes carousel state.
@visibleForTesting
class InteractiveCarouselState extends State<InteractiveCarousel>
    with SingleTickerProviderStateMixin {
  /// Current position index (0-based).
  int currentIndex = 0;

  /// Timer for auto-advance.
  Timer? _autoAdvanceTimer;

  /// Animation controller for entry animations.
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _animationController.forward();
    _startAutoAdvanceTimer();
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant InteractiveCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projects != widget.projects) {
      // Reset index if projects list changed
      if (currentIndex >= widget.projects.length) {
        currentIndex = 0;
      }
      _restartAnimation();
    }
  }

  /// Total number of items in the carousel.
  int get totalItems => widget.projects.length;

  /// The 1-indexed position indicator string: "current/total".
  String get positionIndicator => '${currentIndex + 1}/$totalItems';

  /// Advances to the next item cyclically.
  void goToNext() {
    if (totalItems == 0) return;
    setState(() {
      currentIndex = (currentIndex + 1) % totalItems;
    });
    _restartAnimation();
    _resetAutoAdvanceTimer();
  }

  /// Goes to the previous item cyclically.
  void goToPrevious() {
    if (totalItems == 0) return;
    setState(() {
      currentIndex = (currentIndex - 1 + totalItems) % totalItems;
    });
    _restartAnimation();
    _resetAutoAdvanceTimer();
  }

  /// Starts the auto-advance timer.
  void _startAutoAdvanceTimer() {
    _autoAdvanceTimer?.cancel();
    if (totalItems <= 1) return;
    _autoAdvanceTimer = Timer.periodic(widget.autoAdvanceDuration, (_) {
      goToNextAutomatic();
    });
  }

  /// Auto-advance without resetting the timer (called by timer itself).
  void goToNextAutomatic() {
    if (totalItems == 0) return;
    setState(() {
      currentIndex = (currentIndex + 1) % totalItems;
    });
    _restartAnimation();
  }

  /// Resets the auto-advance timer (called on user interaction).
  void _resetAutoAdvanceTimer() {
    _startAutoAdvanceTimer();
  }

  /// Restarts the entry animation.
  void _restartAnimation() {
    _animationController.reset();
    _animationController.forward();
  }

  /// Handles horizontal drag end for swipe gestures.
  void _onHorizontalDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -100) {
      // Swipe left → next
      goToNext();
    } else if (velocity > 100) {
      // Swipe right → previous
      goToPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.projects.isEmpty) {
      return SizedBox(
        height: widget.height,
        child: Center(
          child: Text(
            'No featured projects',
            style: TextStyle(color: PortfolioTheme.textSecondary),
          ),
        ),
      );
    }

    final project = widget.projects[currentIndex];
    final displayTitle = truncateText(project.title, 60);
    final displayDescription = truncateText(project.description, 200);

    return GestureDetector(
      onHorizontalDragEnd: _onHorizontalDragEnd,
      child: Container(
        height: widget.height,
        width: double.infinity,
        decoration: BoxDecoration(
          color: PortfolioTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          children: [
            // Image with entry animation
            Positioned.fill(
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _buildImage(project),
                  ),
                ),
              ),
            ),
            // Gradient overlay for text readability
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                    stops: const [0.4, 1.0],
                  ),
                ),
              ),
            ),
            // Text content with entry animation
            Positioned(
              left: 24,
              right: 24,
              bottom: 60,
              child: SlideTransition(
                position: _slideAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayDescription,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Navigation buttons
            Positioned(
              left: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                  icon: Icons.chevron_left,
                  onPressed: goToPrevious,
                  tooltip: 'Previous',
                ),
              ),
            ),
            Positioned(
              right: 8,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavButton(
                  icon: Icons.chevron_right,
                  onPressed: goToNext,
                  tooltip: 'Next',
                ),
              ),
            ),
            // Position indicator
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    positionIndicator,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the project image with fallback placeholder.
  Widget _buildImage(PortfolioProject project) {
    return Image.network(
      project.mainImageUrl,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return _buildFallbackPlaceholder(project.title);
      },
    );
  }

  /// Builds the fallback placeholder with primary color background and title.
  Widget _buildFallbackPlaceholder(String title) {
    return Container(
      color: PortfolioTheme.primaryBlue,
      width: double.infinity,
      height: double.infinity,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }

  /// Builds a circular navigation button.
  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
  }) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          child: Icon(
            icon,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
    );
  }
}
