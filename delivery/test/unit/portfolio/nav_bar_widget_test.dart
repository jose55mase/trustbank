import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:delivery_app/portfolio/widgets/portfolio_nav_bar.dart';
import 'package:delivery_app/portfolio/theme/portfolio_theme.dart';

void main() {
  late ScrollController scrollController;
  late List<PortfolioNavLink> testLinks;

  setUp(() {
    scrollController = ScrollController();
    testLinks = [
      PortfolioNavLink(label: 'Home', sectionKey: GlobalKey()),
      PortfolioNavLink(label: 'Projects', sectionKey: GlobalKey()),
      PortfolioNavLink(label: 'Catalog', sectionKey: GlobalKey()),
      PortfolioNavLink(label: 'About', sectionKey: GlobalKey()),
      PortfolioNavLink(label: 'Contact', sectionKey: GlobalKey()),
    ];
  });

  tearDown(() {
    scrollController.dispose();
  });

  Widget buildNavBar({double width = 400}) {
    return MaterialApp(
      theme: PortfolioTheme.lightTheme,
      home: MediaQuery(
        data: MediaQueryData(size: Size(width, 800)),
        child: Scaffold(
          body: Column(
            children: [
              PortfolioNavBar(
                links: testLinks,
                scrollController: scrollController,
              ),
            ],
          ),
        ),
      ),
    );
  }

  group('PortfolioNavBar - Hamburger Menu Toggle', () {
    testWidgets('shows hamburger icon on mobile (< 768px)', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Should find the hamburger icon button
      expect(find.byType(IconButton), findsOneWidget);
      // Should NOT find inline text buttons for links
      expect(find.byType(TextButton), findsNothing);
    });

    testWidgets('shows inline links on desktop (>= 768px)', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 1200));

      // Should find text buttons for each link
      expect(find.byType(TextButton), findsNWidgets(testLinks.length));
      // Should NOT find hamburger icon
      expect(find.byType(IconButton), findsNothing);
    });

    testWidgets('menu is initially closed on mobile', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      final state = tester.state<PortfolioNavBarState>(
        find.byType(PortfolioNavBar),
      );
      expect(state.isMenuOpen, isFalse);
    });

    testWidgets('tapping hamburger icon opens the menu panel', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Tap the hamburger icon
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final state = tester.state<PortfolioNavBarState>(
        find.byType(PortfolioNavBar),
      );
      expect(state.isMenuOpen, isTrue);

      // Menu panel should show all link labels
      for (final link in testLinks) {
        expect(find.text(link.label), findsOneWidget);
      }
    });

    testWidgets('tapping hamburger icon again closes the menu panel',
        (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Open menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final state = tester.state<PortfolioNavBarState>(
        find.byType(PortfolioNavBar),
      );
      expect(state.isMenuOpen, isTrue);

      // Close menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      expect(state.isMenuOpen, isFalse);
    });

    testWidgets('tapping a link in the mobile menu closes the panel',
        (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Open menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      final state = tester.state<PortfolioNavBarState>(
        find.byType(PortfolioNavBar),
      );
      expect(state.isMenuOpen, isTrue);

      // Tap a link in the menu
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(state.isMenuOpen, isFalse);
    });

    testWidgets('nav bar displays the title', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      expect(find.text('Portfolio'), findsOneWidget);
    });

    testWidgets('nav bar uses PortfolioTheme surface color', (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Find the main container of the nav bar
      final container = tester.widget<Container>(
        find.descendant(
          of: find.byType(PortfolioNavBar),
          matching: find.byType(Container).first,
        ),
      );

      final decoration = container.decoration as BoxDecoration?;
      expect(decoration?.color, equals(PortfolioTheme.surface));
    });

    testWidgets('mobile menu items have minimum 44px touch target',
        (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      // Open menu
      await tester.tap(find.byType(IconButton));
      await tester.pumpAndSettle();

      // Check that InkWell items have min height constraint
      final inkWells = tester.widgetList<InkWell>(
        find.descendant(
          of: find.byType(SizeTransition),
          matching: find.byType(InkWell),
        ),
      );

      for (final inkWell in inkWells) {
        // The InkWell wraps a Container with minHeight: 44
        expect(inkWell, isNotNull);
      }

      // Verify the container constraints
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(SizeTransition),
          matching: find.byType(Container),
        ),
      );

      // At least one container should have minHeight >= 44
      final hasMinHeight = containers.any((c) {
        final constraints = c.constraints;
        return constraints != null && constraints.minHeight >= 44;
      });
      expect(hasMinHeight, isTrue);
    });

    testWidgets('hamburger icon has minimum 44x44 touch target',
        (tester) async {
      await tester.pumpWidget(buildNavBar(width: 600));

      final iconButton = tester.widget<IconButton>(find.byType(IconButton));
      expect(iconButton.constraints?.minWidth, greaterThanOrEqualTo(44));
      expect(iconButton.constraints?.minHeight, greaterThanOrEqualTo(44));
    });
  });

  group('PortfolioNavBar - Scroll Animation', () {
    testWidgets('scrollDuration defaults to 400ms (within 300-500ms range)',
        (tester) async {
      await tester.pumpWidget(buildNavBar(width: 1200));

      final navBar = tester.widget<PortfolioNavBar>(
        find.byType(PortfolioNavBar),
      );
      expect(
        navBar.scrollDuration.inMilliseconds,
        greaterThanOrEqualTo(300),
      );
      expect(
        navBar.scrollDuration.inMilliseconds,
        lessThanOrEqualTo(500),
      );
    });
  });
}
