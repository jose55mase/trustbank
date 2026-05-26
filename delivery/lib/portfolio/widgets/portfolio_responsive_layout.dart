import 'package:flutter/material.dart';

/// Breakpoint categories for the portfolio responsive layout.
///
/// - [mobile]: width < 768px — single column, 44x44px min touch targets
/// - [tablet]: 768px <= width <= 1024px — margins of 24px (min) to 5% (max)
/// - [desktop]: width > 1024px — max content width 1200px, centered
enum PortfolioBreakpoint {
  mobile,
  tablet,
  desktop;

  /// The lower bound width for this breakpoint (inclusive).
  double get minWidth => switch (this) {
        PortfolioBreakpoint.mobile => 0,
        PortfolioBreakpoint.tablet => 768,
        PortfolioBreakpoint.desktop => 1025,
      };

  /// Whether this breakpoint represents a mobile layout.
  bool get isMobile => this == PortfolioBreakpoint.mobile;

  /// Whether this breakpoint represents a tablet layout.
  bool get isTablet => this == PortfolioBreakpoint.tablet;

  /// Whether this breakpoint represents a desktop layout.
  bool get isDesktop => this == PortfolioBreakpoint.desktop;

  /// Determines the breakpoint for a given screen [width].
  static PortfolioBreakpoint fromWidth(double width) {
    if (width > 1024) return PortfolioBreakpoint.desktop;
    if (width >= 768) return PortfolioBreakpoint.tablet;
    return PortfolioBreakpoint.mobile;
  }
}

/// Data class holding responsive layout information for child widgets.
class PortfolioLayoutData {
  const PortfolioLayoutData({
    required this.breakpoint,
    required this.screenWidth,
    required this.contentWidth,
    required this.horizontalPadding,
  });

  /// The current breakpoint category.
  final PortfolioBreakpoint breakpoint;

  /// The full screen width available.
  final double screenWidth;

  /// The effective content width after applying constraints and padding.
  final double contentWidth;

  /// The horizontal padding applied on each side.
  final double horizontalPadding;

  /// Minimum touch target size for interactive elements (44x44 on mobile).
  double get minTouchTarget => breakpoint.isMobile ? 44.0 : 0.0;
}

/// A responsive layout widget for the portfolio module.
///
/// Wraps content with proper constraints based on the current screen width:
/// - Mobile (<768px): full width, single column layout
/// - Tablet (768-1024px): margins of at least 24px, max 5% of screen width
/// - Desktop (>1024px): max content width of 1200px, centered horizontally
///
/// Uses a builder pattern so child widgets can access the current breakpoint
/// and adapt their layout accordingly.
///
/// Requirements: 8.1, 8.2, 8.3, 8.5
class PortfolioResponsiveLayout extends StatelessWidget {
  const PortfolioResponsiveLayout({
    super.key,
    required this.builder,
    this.backgroundColor,
  });

  /// Builder function that receives [PortfolioLayoutData] with the current
  /// breakpoint and layout constraints.
  final Widget Function(BuildContext context, PortfolioLayoutData layoutData)
      builder;

  /// Optional background color for the layout container.
  final Color? backgroundColor;

  /// Maximum content width for desktop layout.
  static const double maxContentWidth = 1200.0;

  /// Minimum margin for tablet layout.
  static const double tabletMinMargin = 24.0;

  /// Maximum margin percentage for tablet layout (5% of screen width).
  static const double tabletMaxMarginPercent = 0.05;

  /// Computes the horizontal padding for a given [screenWidth] and [breakpoint].
  static double computeHorizontalPadding(
    double screenWidth,
    PortfolioBreakpoint breakpoint,
  ) {
    switch (breakpoint) {
      case PortfolioBreakpoint.mobile:
        return 16.0;
      case PortfolioBreakpoint.tablet:
        // At least 24px, but no more than 5% of screen width
        final percentMargin = screenWidth * tabletMaxMarginPercent;
        return percentMargin.clamp(tabletMinMargin, percentMargin);
      case PortfolioBreakpoint.desktop:
        // Center content with max width of 1200px
        final sideMargin = (screenWidth - maxContentWidth) / 2;
        return sideMargin > 0 ? sideMargin : 24.0;
    }
  }

  /// Computes the effective content width for a given [screenWidth] and [breakpoint].
  static double computeContentWidth(
    double screenWidth,
    PortfolioBreakpoint breakpoint,
  ) {
    final padding = computeHorizontalPadding(screenWidth, breakpoint);
    final available = screenWidth - (padding * 2);
    if (breakpoint == PortfolioBreakpoint.desktop) {
      return available.clamp(0, maxContentWidth);
    }
    return available.clamp(0, screenWidth);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final breakpoint = PortfolioBreakpoint.fromWidth(screenWidth);
        final horizontalPadding =
            computeHorizontalPadding(screenWidth, breakpoint);
        final contentWidth = computeContentWidth(screenWidth, breakpoint);

        final layoutData = PortfolioLayoutData(
          breakpoint: breakpoint,
          screenWidth: screenWidth,
          contentWidth: contentWidth,
          horizontalPadding: horizontalPadding,
        );

        return Container(
          color: backgroundColor,
          width: screenWidth,
          child: ClipRect(
            // Prevents horizontal overflow
            child: OverflowBox(
              maxWidth: screenWidth,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: screenWidth,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: breakpoint == PortfolioBreakpoint.desktop
                            ? maxContentWidth
                            : double.infinity,
                      ),
                      child: builder(context, layoutData),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// A wrapper widget that ensures images maintain their aspect ratio
/// and never overflow their container.
///
/// Requirements: 8.5
class PortfolioResponsiveImage extends StatelessWidget {
  const PortfolioResponsiveImage({
    super.key,
    required this.imageProvider,
    this.fit = BoxFit.contain,
    this.aspectRatio,
    this.borderRadius,
    this.placeholder,
  });

  /// The image to display.
  final ImageProvider imageProvider;

  /// How the image should be inscribed into the container.
  /// Defaults to [BoxFit.contain] to maintain aspect ratio.
  final BoxFit fit;

  /// Optional fixed aspect ratio for the image container.
  final double? aspectRatio;

  /// Optional border radius for the image.
  final BorderRadius? borderRadius;

  /// Optional placeholder widget shown while loading or on error.
  final Widget? placeholder;

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = Image(
      image: imageProvider,
      fit: fit,
      width: double.infinity,
      errorBuilder: (context, error, stackTrace) {
        return placeholder ?? const SizedBox.shrink();
      },
    );

    if (borderRadius != null) {
      imageWidget = ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }

    if (aspectRatio != null) {
      return AspectRatio(
        aspectRatio: aspectRatio!,
        child: imageWidget,
      );
    }

    return imageWidget;
  }
}

/// Extension on [BuildContext] for convenient breakpoint access.
extension PortfolioBreakpointExtension on BuildContext {
  /// Returns the current [PortfolioBreakpoint] based on the screen width.
  PortfolioBreakpoint get portfolioBreakpoint {
    final width = MediaQuery.sizeOf(this).width;
    return PortfolioBreakpoint.fromWidth(width);
  }

  /// Whether the current screen is in mobile layout.
  bool get isMobileLayout => portfolioBreakpoint.isMobile;

  /// Whether the current screen is in tablet layout.
  bool get isTabletLayout => portfolioBreakpoint.isTablet;

  /// Whether the current screen is in desktop layout.
  bool get isDesktopLayout => portfolioBreakpoint.isDesktop;
}
