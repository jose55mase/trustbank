import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/theme/portfolio_theme.dart';
import 'package:delivery_app/portfolio/widgets/project_detail_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create a test project with given parameters.
PortfolioProject _makeProject({
  String id = '1',
  String title = 'Test Project Title',
  String description =
      'This is a full project description that should not be truncated in the detail view.',
  String mainImageUrl = 'https://example.com/main.png',
  List<String> additionalImageUrls = const [],
  String? externalLink,
  List<String> technologies = const [],
  bool isFeatured = false,
}) {
  return PortfolioProject(
    id: id,
    title: title,
    description: description,
    mainImageUrl: mainImageUrl,
    additionalImageUrls: additionalImageUrls,
    externalLink: externalLink,
    technologies: technologies,
    isFeatured: isFeatured,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

/// Wraps the detail view in a MaterialApp with PortfolioTheme for testing.
Widget _buildTestDetailView({
  required PortfolioProject project,
  VoidCallback? onExternalLinkTap,
  VoidCallback? onBackPressed,
}) {
  return MaterialApp(
    theme: PortfolioTheme.lightTheme,
    home: Scaffold(
      body: ProjectDetailView(
        project: project,
        onExternalLinkTap: onExternalLinkTap,
        onBackPressed: onBackPressed,
      ),
    ),
  );
}

void main() {
  group('ProjectDetailView - Title Display', () {
    testWidgets('displays full project title without truncation',
        (tester) async {
      final longTitle = 'A' * 100; // Max title length
      final project = _makeProject(title: longTitle);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      // Title appears in both the title Text widget and the image fallback
      // placeholder (since network images fail in tests). Use findsWidgets.
      expect(find.text(longTitle), findsWidgets);

      // Verify the title is rendered with the correct style (28px bold)
      final titleFinder = find.text(longTitle);
      final titleWidgets = tester.widgetList<Text>(titleFinder);
      final titleWidget = titleWidgets.firstWhere(
        (w) => w.style?.fontSize == 28,
      );
      expect(titleWidget.style?.fontWeight, FontWeight.bold);
    });

    testWidgets('displays short title correctly', (tester) async {
      final project = _makeProject(title: 'My Project');

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      // Title appears in title section and image fallback
      expect(find.text('My Project'), findsWidgets);
    });
  });

  group('ProjectDetailView - Description Display', () {
    testWidgets('displays full untruncated description', (tester) async {
      final longDescription = 'B' * 500; // Max description length
      final project = _makeProject(description: longDescription);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text(longDescription), findsOneWidget);
    });

    testWidgets('displays multi-line description', (tester) async {
      const description =
          'This is a detailed description of the project. It contains multiple sentences and should be displayed in full without any truncation or ellipsis.';
      final project = _makeProject(description: description);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text(description), findsOneWidget);
    });
  });

  group('ProjectDetailView - Technologies', () {
    testWidgets('displays technologies as chips', (tester) async {
      final project = _makeProject(
        technologies: ['Flutter', 'Dart', 'Firebase'],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      expect(find.text('Firebase'), findsOneWidget);
      expect(find.byType(Chip), findsNWidgets(3));
    });

    testWidgets('hides technologies section when empty', (tester) async {
      final project = _makeProject(technologies: []);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.byType(Chip), findsNothing);
    });

    testWidgets('displays single technology', (tester) async {
      final project = _makeProject(technologies: ['React']);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('React'), findsOneWidget);
      expect(find.byType(Chip), findsOneWidget);
    });
  });

  group('ProjectDetailView - External Link', () {
    testWidgets('shows external link button when link is present',
        (tester) async {
      final project = _makeProject(
        externalLink: 'https://example.com/project',
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('View Project'), findsOneWidget);
      expect(find.byIcon(Icons.open_in_new), findsOneWidget);
    });

    testWidgets('hides external link button when link is null',
        (tester) async {
      final project = _makeProject(externalLink: null);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('View Project'), findsNothing);
    });

    testWidgets('hides external link button when link is empty',
        (tester) async {
      final project = _makeProject(externalLink: '');

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('View Project'), findsNothing);
    });

    testWidgets('calls onExternalLinkTap when button is pressed',
        (tester) async {
      var tapped = false;
      final project = _makeProject(
        externalLink: 'https://example.com/project',
      );

      await tester.pumpWidget(_buildTestDetailView(
        project: project,
        onExternalLinkTap: () => tapped = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('View Project'));
      expect(tapped, isTrue);
    });
  });

  group('ProjectDetailView - Images', () {
    testWidgets('displays main image area', (tester) async {
      final project = _makeProject(
        mainImageUrl: 'https://example.com/main.png',
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      // In test environment, network images fail, so fallback shows
      // The AspectRatio widget wrapping the main image should be present
      expect(find.byType(AspectRatio), findsWidgets);
    });

    testWidgets('shows fallback placeholder when main image fails',
        (tester) async {
      final project = _makeProject(
        title: 'Fallback Test',
        mainImageUrl: 'https://invalid-url.com/fail.png',
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      // Fallback shows the project title (appears in both title and placeholder)
      expect(find.text('Fallback Test'), findsWidgets);
    });

    testWidgets('displays gallery section when additional images exist',
        (tester) async {
      final project = _makeProject(
        additionalImageUrls: [
          'https://example.com/img1.png',
          'https://example.com/img2.png',
          'https://example.com/img3.png',
        ],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('hides gallery section when no additional images',
        (tester) async {
      final project = _makeProject(additionalImageUrls: []);

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      expect(find.text('Gallery'), findsNothing);
      expect(find.byType(GridView), findsNothing);
    });
  });

  group('ProjectDetailView - Responsive Layout', () {
    testWidgets('uses single column gallery on mobile', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final project = _makeProject(
        additionalImageUrls: [
          'https://example.com/img1.png',
          'https://example.com/img2.png',
        ],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 1);
    });

    testWidgets('uses two column gallery on tablet', (tester) async {
      tester.view.physicalSize = const Size(900, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final project = _makeProject(
        additionalImageUrls: [
          'https://example.com/img1.png',
          'https://example.com/img2.png',
        ],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 2);
    });

    testWidgets('uses three column gallery on desktop', (tester) async {
      tester.view.physicalSize = const Size(1300, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final project = _makeProject(
        additionalImageUrls: [
          'https://example.com/img1.png',
          'https://example.com/img2.png',
          'https://example.com/img3.png',
        ],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate =
          gridView.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegate.crossAxisCount, 3);
    });
  });

  group('ProjectDetailView - Back Button', () {
    testWidgets('shows back button when onBackPressed is provided',
        (tester) async {
      final project = _makeProject();

      await tester.pumpWidget(_buildTestDetailView(
        project: project,
        onBackPressed: () {},
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
      expect(find.text('Back'), findsOneWidget);
    });

    testWidgets('hides back button when onBackPressed is null',
        (tester) async {
      final project = _makeProject();

      await tester.pumpWidget(_buildTestDetailView(
        project: project,
        onBackPressed: null,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back), findsNothing);
    });

    testWidgets('calls onBackPressed when back button is tapped',
        (tester) async {
      var pressed = false;
      final project = _makeProject();

      await tester.pumpWidget(_buildTestDetailView(
        project: project,
        onBackPressed: () => pressed = true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Back'));
      expect(pressed, isTrue);
    });
  });

  group('ProjectDetailView - Completeness', () {
    testWidgets('displays all project data fields', (tester) async {
      final project = _makeProject(
        title: 'Complete Project',
        description: 'Full description of the project with all details.',
        technologies: ['Flutter', 'Dart'],
        externalLink: 'https://example.com',
        additionalImageUrls: ['https://example.com/extra.png'],
      );

      await tester.pumpWidget(_buildTestDetailView(project: project));
      await tester.pumpAndSettle();

      // Title (appears in title section and image fallback)
      expect(find.text('Complete Project'), findsWidgets);
      // Description
      expect(
        find.text('Full description of the project with all details.'),
        findsOneWidget,
      );
      // Technologies
      expect(find.text('Flutter'), findsOneWidget);
      expect(find.text('Dart'), findsOneWidget);
      // External link
      expect(find.text('View Project'), findsOneWidget);
      // Gallery
      expect(find.text('Gallery'), findsOneWidget);
    });
  });
}
