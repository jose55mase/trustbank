import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/widgets/interactive_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create a test project with given parameters.
PortfolioProject _makeProject({
  String id = '1',
  String title = 'Test Project',
  String description = 'A test project description',
  String imageUrl = 'https://example.com/image.png',
  bool isFeatured = true,
}) {
  return PortfolioProject(
    id: id,
    title: title,
    description: description,
    mainImageUrl: imageUrl,
    isFeatured: isFeatured,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Wraps the carousel in a MaterialApp for testing.
Widget _buildTestCarousel({
  required List<PortfolioProject> projects,
  Duration autoAdvanceDuration = const Duration(seconds: 5),
}) {
  return MaterialApp(
    home: Scaffold(
      body: InteractiveCarousel(
        projects: projects,
        autoAdvanceDuration: autoAdvanceDuration,
      ),
    ),
  );
}

void main() {
  group('truncateText', () {
    test('returns text unchanged when within limit', () {
      expect(truncateText('Hello', 60), 'Hello');
    });

    test('returns text unchanged when exactly at limit', () {
      final text = 'a' * 60;
      expect(truncateText(text, 60), text);
    });

    test('truncates text exceeding limit with ellipsis', () {
      final text = 'a' * 61;
      final result = truncateText(text, 60);
      expect(result.length, 60);
      expect(result.endsWith('…'), isTrue);
      expect(result, '${'a' * 59}…');
    });

    test('truncates description at 200 chars', () {
      final text = 'b' * 250;
      final result = truncateText(text, 200);
      expect(result.length, 200);
      expect(result.endsWith('…'), isTrue);
    });

    test('preserves short description unchanged', () {
      const text = 'Short description';
      expect(truncateText(text, 200), text);
    });

    test('handles empty string', () {
      expect(truncateText('', 60), '');
    });

    test('handles single character within limit', () {
      expect(truncateText('a', 60), 'a');
    });
  });

  group('InteractiveCarousel - Cyclic Navigation', () {
    testWidgets('goToNext advances index cyclically', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      state.goToNext();
      expect(state.currentIndex, 1);

      state.goToNext();
      expect(state.currentIndex, 2);

      // Cyclic: after last, goes back to first
      state.goToNext();
      expect(state.currentIndex, 0);
    });

    testWidgets('goToPrevious goes back cyclically', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      // Cyclic: before first, goes to last
      state.goToPrevious();
      expect(state.currentIndex, 2);

      state.goToPrevious();
      expect(state.currentIndex, 1);

      state.goToPrevious();
      expect(state.currentIndex, 0);
    });

    testWidgets('single item carousel stays at index 0', (tester) async {
      final projects = [_makeProject()];

      await tester.pumpWidget(_buildTestCarousel(projects: projects));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      state.goToNext();
      expect(state.currentIndex, 0);

      state.goToPrevious();
      expect(state.currentIndex, 0);
    });
  });

  group('InteractiveCarousel - Position Indicator', () {
    testWidgets('shows correct position indicator', (tester) async {
      final projects = List.generate(
        5,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.positionIndicator, '1/5');

      state.goToNext();
      expect(state.positionIndicator, '2/5');

      state.goToNext();
      state.goToNext();
      state.goToNext();
      expect(state.positionIndicator, '5/5');

      state.goToNext();
      expect(state.positionIndicator, '1/5');
    });

    testWidgets('position indicator is displayed in UI', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      expect(find.text('1/3'), findsOneWidget);
    });
  });

  group('InteractiveCarousel - Auto-advance Timer', () {
    testWidgets('auto-advances after specified duration', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(
        projects: projects,
        autoAdvanceDuration: const Duration(seconds: 5),
      ));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      // Advance time by 5 seconds
      await tester.pump(const Duration(seconds: 5));
      expect(state.currentIndex, 1);

      // Advance again
      await tester.pump(const Duration(seconds: 5));
      expect(state.currentIndex, 2);

      // Cyclic
      await tester.pump(const Duration(seconds: 5));
      expect(state.currentIndex, 0);
    });

    testWidgets('user interaction resets auto-advance timer', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(
        projects: projects,
        autoAdvanceDuration: const Duration(seconds: 5),
      ));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      // Wait 3 seconds (not enough to auto-advance)
      await tester.pump(const Duration(seconds: 3));
      expect(state.currentIndex, 0);

      // User navigates manually — resets timer
      state.goToNext();
      expect(state.currentIndex, 1);

      // Wait 3 seconds again — timer was reset, so no auto-advance
      await tester.pump(const Duration(seconds: 3));
      expect(state.currentIndex, 1);

      // Wait full 5 seconds from last interaction — now auto-advances
      await tester.pump(const Duration(seconds: 2));
      expect(state.currentIndex, 2);
    });

    testWidgets('no auto-advance with single item', (tester) async {
      final projects = [_makeProject()];

      await tester.pumpWidget(_buildTestCarousel(
        projects: projects,
        autoAdvanceDuration: const Duration(seconds: 5),
      ));

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      await tester.pump(const Duration(seconds: 10));
      expect(state.currentIndex, 0);
    });
  });

  group('InteractiveCarousel - UI Elements', () {
    testWidgets('displays truncated title and description', (tester) async {
      final longTitle = 'A' * 80;
      final longDesc = 'B' * 250;
      final projects = [
        _makeProject(title: longTitle, description: longDesc),
      ];

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      // Title should be truncated to 60 chars
      final expectedTitle = '${'A' * 59}…';
      expect(find.text(expectedTitle), findsOneWidget);

      // Description should be truncated to 200 chars
      final expectedDesc = '${'B' * 199}…';
      expect(find.text(expectedDesc), findsOneWidget);
    });

    testWidgets('shows navigation buttons', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    });

    testWidgets('tapping next button advances carousel', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();

      expect(state.currentIndex, 1);
    });

    testWidgets('tapping previous button goes back', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      await tester.tap(find.byIcon(Icons.chevron_left));
      await tester.pump();

      expect(state.currentIndex, 2); // Cyclic: 0 - 1 + 3 = 2
    });

    testWidgets('shows empty state when no projects', (tester) async {
      await tester.pumpWidget(_buildTestCarousel(projects: []));
      await tester.pumpAndSettle();

      expect(find.text('No featured projects'), findsOneWidget);
    });

    testWidgets('shows fallback placeholder when image fails', (tester) async {
      final projects = [
        _makeProject(
          title: 'My Project',
          imageUrl: 'https://invalid-url-that-will-fail.com/img.png',
        ),
      ];

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      // The Image.network errorBuilder should trigger the fallback
      // In test environment, network images fail, so the fallback shows
      expect(find.text('My Project'), findsWidgets);
    });
  });

  group('InteractiveCarousel - Swipe Gestures', () {
    testWidgets('swipe left advances to next', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      // Swipe left (drag from right to left)
      await tester.fling(
        find.byType(InteractiveCarousel),
        const Offset(-200, 0),
        1000,
      );
      await tester.pump();

      expect(state.currentIndex, 1);
    });

    testWidgets('swipe right goes to previous', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCarousel(projects: projects));
      await tester.pumpAndSettle();

      final state = tester.state<InteractiveCarouselState>(
        find.byType(InteractiveCarousel),
      );

      expect(state.currentIndex, 0);

      // Swipe right (drag from left to right)
      await tester.fling(
        find.byType(InteractiveCarousel),
        const Offset(200, 0),
        1000,
      );
      await tester.pump();

      expect(state.currentIndex, 2); // Cyclic
    });
  });
}
