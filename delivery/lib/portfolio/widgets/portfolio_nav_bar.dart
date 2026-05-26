import 'package:flutter/material.dart';

import '../theme/portfolio_theme.dart';
import 'portfolio_responsive_layout.dart';

/// A navigation link item for the portfolio nav bar.
class PortfolioNavLink {
  const PortfolioNavLink({
    required this.label,
    required this.sectionKey,
  });

  /// Display label for the link.
  final String label;

  /// Key identifying the section to scroll to.
  final GlobalKey sectionKey;
}

/// Fixed-position navigation bar for the portfolio public page.
///
/// Features:
/// - Always visible during scroll (fixed position)
/// - Links to all public sections with smooth scroll animation (300-500ms)
/// - Collapses to hamburger menu on screens < 768px
/// - Uses PortfolioTheme pastel colors
///
/// Requirements: 1.1, 1.2, 1.3, 1.4, 1.5
class PortfolioNavBar extends StatefulWidget {
  const PortfolioNavBar({
    super.key,
    required this.links,
    required this.scrollController,
    this.title = 'Portfolio',
    this.scrollDuration = const Duration(milliseconds: 400),
  });

  /// Navigation links to display.
  final List<PortfolioNavLink> links;

  /// ScrollController used to animate scrolling to sections.
  final ScrollController scrollController;

  /// Title displayed on the left side of the nav bar.
  final String title;

  /// Duration of the smooth scroll animation (must be 300-500ms).
  final Duration scrollDuration;

  @override
  State<PortfolioNavBar> createState() => PortfolioNavBarState();
}

/// Visible for testing — exposes hamburger menu state.
@visibleForTesting
class PortfolioNavBarState extends State<PortfolioNavBar>
    with SingleTickerProviderStateMixin {
  /// Whether the mobile menu panel is expanded.
  bool isMenuOpen = false;

  late AnimationController _animationController;
  late Animation<double> _menuAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _menuAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  /// Toggles the hamburger menu open/closed state.
  void toggleMenu() {
    setState(() {
      isMenuOpen = !isMenuOpen;
      if (isMenuOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  /// Scrolls to the section identified by [link] with smooth animation.
  void scrollToSection(PortfolioNavLink link) {
    final context = link.sectionKey.currentContext;
    if (context != null) {
      Scrollable.ensureVisible(
        context,
        duration: widget.scrollDuration,
        curve: Curves.easeInOut,
      );
    }

    // Close menu if open (mobile)
    if (isMenuOpen) {
      toggleMenu();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final breakpoint = PortfolioBreakpoint.fromWidth(screenWidth);
    final isMobile = breakpoint.isMobile;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildNavBarContent(isMobile),
        if (isMobile) _buildMobileMenuPanel(),
      ],
    );
  }

  Widget _buildNavBarContent(bool isMobile) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        color: PortfolioTheme.surface,
        boxShadow: [
          BoxShadow(
            color: PortfolioTheme.accentBlack.withOpacity(0.08),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Title / Brand
          Text(
            widget.title,
            style: TextStyle(
              color: PortfolioTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          // Desktop/Tablet: show links inline
          if (!isMobile) _buildDesktopLinks(),
          // Mobile: show hamburger icon
          if (isMobile) _buildHamburgerIcon(),
        ],
      ),
    );
  }

  Widget _buildDesktopLinks() {
    return Flexible(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        children: widget.links.map((link) {
          return Flexible(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextButton(
                onPressed: () => scrollToSection(link),
                style: TextButton.styleFrom(
                  foregroundColor: PortfolioTheme.textPrimary,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                child: Text(
                  link.label,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildHamburgerIcon() {
    return IconButton(
      icon: AnimatedIcon(
        icon: AnimatedIcons.menu_close,
        progress: _menuAnimation,
        color: PortfolioTheme.textPrimary,
      ),
      onPressed: toggleMenu,
      tooltip: isMenuOpen ? 'Close menu' : 'Open menu',
      iconSize: 24,
      constraints: const BoxConstraints(
        minWidth: 44,
        minHeight: 44,
      ),
    );
  }

  Widget _buildMobileMenuPanel() {
    return SizeTransition(
      sizeFactor: _menuAnimation,
      axisAlignment: -1.0,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: PortfolioTheme.surface,
          border: Border(
            top: BorderSide(
              color: PortfolioTheme.divider,
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: PortfolioTheme.accentBlack.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: widget.links.map((link) {
            return InkWell(
              onTap: () => scrollToSection(link),
              child: Container(
                constraints: const BoxConstraints(minHeight: 44),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Text(
                  link.label,
                  style: TextStyle(
                    color: PortfolioTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
