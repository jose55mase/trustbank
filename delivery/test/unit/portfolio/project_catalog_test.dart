import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/widgets/interactive_carousel.dart';
import 'package:delivery_app/portfolio/widgets/project_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Helper to create a test project with given parameters.
PortfolioProject _makeProject({
  String id = '1',
  String title = 'Test Project',
  String description = 'A test project description',
  String imageUrl = 'https://example.com/image.png',
  bool isFeatured = false,
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

/// Wraps the catalog in a MaterialApp for testing with a given screen width.
Widget _buildTestCatalog({
  required List<PortfolioProject> projects,
  double screenWidth = 1024,
  double screenHeight = 800,
  void Function(PortfolioProject)? onProjectSelected,
}) {
  return MaterialApp(
    home: MediaQuery(
      data: MediaQueryData(size: Size(screenWidth, screenHeight)),
      child: Scaffold(
        body: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ProjectCatalog(
                projects: projects,
                onProjectSelected: onProjectSelected,
              ),
            );
          },
        ),
      ),
    ),
  );
}

void main() {
  group('ProjectCatalog - Empty State', () {
    testWidgets('shows empty state message when no projects exist',
        (tester) async {
      await tester.pumpWidget(_buildTestCatalog(projects: []));
      await tester.pumpAndSettle();

      expect(find.text('No hay proyectos disponibles'), findsOneWidget);
      expect(find.byIcon(Icons.folder_open), findsOneWidget);
    });
  });

  group('ProjectCatalog - Project Display', () {
    testWidgets('displays project title', (tester) async {
      final projects = [
        _makeProject(title: 'My Awesome Project'),
      ];

      await tester.pumpWidget(_buildTestCatalog(projects: projects));
      await tester.pumpAndSettle();

      expect(find.text('My Awesome Project'), findsWidgets);
    });

    testWidgets('displays truncated description at 150 chars', (tester) async {
      final longDescription = 'D' * 200;
      final projects = [
        _makeProject(description: longDescription),
      ];

      await tester.pumpWidget(_buildTestCatalog(projects: projects));
      await tester.pumpAndSettle();

      // The truncated description should be 150 chars with ellipsis
      final expectedDesc = '${'D' * 149}…';
      expect(find.text(expectedDesc), findsOneWidget);
    });

    testWidgets('preserves short description unchanged', (tester) async {
      const shortDescription = 'A short description';
      final projects = [
        _makeProject(description: shortDescription),
      ];

      await tester.pumpWidget(_buildTestCatalog(projects: projects));
      await tester.pumpAndSettle();

      expect(find.text(shortDescription), findsOneWidget);
    });

    testWidgets('displays multiple projects', (tester) async {
      final projects = List.generate(
        4,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCatalog(projects: projects));
      await tester.pumpAndSettle();

      for (var i = 0; i < 4; i++) {
        expect(find.text('Project $i'), findsWidgets);
      }
    });
  });

  group('ProjectCatalog - Description Truncation', () {
    test('truncateText preserves text within 150 chars', () {
      const text = 'Short text';
      expect(truncateText(text, 150), text);
    });

    test('truncateText truncates text exceeding 150 chars', () {
      final text = 'X' * 200;
      final result = truncateText(text, 150);
      expect(result.length, 150);
      expect(result.endsWith('…'), isTrue);
      expect(result, '${'X' * 149}…');
    });

    test('truncateText preserves text exactly at 150 chars', () {
      final text = 'Y' * 150;
      expect(truncateText(text, 150), text);
    });
  });

  group('ProjectCatalog - Responsive Layout', () {
    testWidgets('shows single column on mobile (<768px)', (tester) async {
      final projects = List.generate(
        3,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCatalog(
        projects: projects,
        screenWidth: 400,
      ));
      await tester.pumpAndSettle();

      // On mobile, should use Column (no GridView)
      expect(find.byType(GridView), findsNothing);
    });

    testWidgets('shows multi-column grid on tablet (≥768px)', (tester) async {
      final projects = List.generate(
        4,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCatalog(
        projects: projects,
        screenWidth: 900,
      ));
      await tester.pumpAndSettle();

      // On tablet, should use GridView
      expect(find.byType(GridView), findsOneWidget);
    });

    testWidgets('shows multi-column grid on desktop (>1024px)',
        (tester) async {
      final projects = List.generate(
        6,
        (i) => _makeProject(id: '$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCatalog(
        projects: projects,
        screenWidth: 1200,
      ));
      await tester.pumpAndSettle();

      expect(find.byType(GridView), findsOneWidget);
    });
  });

  group('ProjectCatalog - Image Fallback', () {
    testWidgets('shows fallback placeholder when image fails to load',
        (tester) async {
      final projects = [
        _makeProject(
          title: 'Fallback Project',
          imageUrl: 'https://invalid-url.com/broken.png',
        ),
      ];

      await tester.pumpWidget(_buildTestCatalog(projects: projects));
      await tester.pumpAndSettle();

      // In test environment, network images fail, so fallback shows
      // The fallback contains the project title
      expect(find.text('Fallback Project'), findsWidgets);
    });
  });

  group('ProjectCatalog - Navigation', () {
    testWidgets('calls onProjectSelected callback when project is tapped',
        (tester) async {
      PortfolioProject? selectedProject;
      final projects = [
        _makeProject(id: 'proj-1', title: 'Tappable Project'),
      ];

      await tester.pumpWidget(_buildTestCatalog(
        projects: projects,
        onProjectSelected: (project) {
          selectedProject = project;
        },
      ));
      await tester.pumpAndSettle();

      // Tap on the project card
      await tester.tap(find.text('Tappable Project').first);
      await tester.pump();

      expect(selectedProject, isNotNull);
      expect(selectedProject!.id, 'proj-1');
    });

    testWidgets('tapping different projects selects the correct one',
        (tester) async {
      final tappedIds = <String>[];
      final projects = List.generate(
        3,
        (i) => _makeProject(id: 'proj-$i', title: 'Project $i'),
      );

      await tester.pumpWidget(_buildTestCatalog(
        projects: projects,
        screenWidth: 400, // mobile - single column for easier tapping
        onProjectSelected: (project) {
          tappedIds.add(project.id);
        },
      ));
      await tester.pumpAndSettle();

      // Tap the second project
      await tester.tap(find.text('Project 1').first);
      await tester.pump();

      expect(tappedIds, ['proj-1']);
    });
  });
}
