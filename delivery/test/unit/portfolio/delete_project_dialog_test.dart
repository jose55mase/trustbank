import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/providers/portfolio_providers.dart';
import 'package:delivery_app/portfolio/repositories/image_storage_repository.dart';
import 'package:delivery_app/portfolio/repositories/portfolio_project_repository.dart';
import 'package:delivery_app/portfolio/widgets/delete_project_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockProjectRepository extends Mock implements PortfolioProjectRepository {}

class MockImageStorageRepository extends Mock implements ImageStorageRepository {}

// --- Helpers ---

PortfolioProject _makeProject({
  String id = 'proj-1',
  String title = 'Test Project',
  String mainImageUrl = 'https://example.com/main.png',
  List<String> additionalImageUrls = const [],
}) {
  return PortfolioProject(
    id: id,
    title: title,
    description: 'A test project',
    mainImageUrl: mainImageUrl,
    additionalImageUrls: additionalImageUrls,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 1, 1),
  );
}

Widget _buildTestApp({
  required PortfolioProject project,
  required MockProjectRepository projectRepo,
  required MockImageStorageRepository imageRepo,
}) {
  return ProviderScope(
    overrides: [
      projectRepositoryProvider.overrideWithValue(projectRepo),
      imageStorageProvider.overrideWithValue(imageRepo),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => DeleteProjectDialog.show(context, project),
            child: const Text('Delete'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  late MockProjectRepository mockProjectRepo;
  late MockImageStorageRepository mockImageRepo;

  setUp(() {
    mockProjectRepo = MockProjectRepository();
    mockImageRepo = MockImageStorageRepository();
  });

  group('DeleteProjectDialog - Confirmation Dialog', () {
    testWidgets('shows confirmation dialog with project title', (tester) async {
      final project = _makeProject(title: 'My Portfolio App');

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Tap the button to show the dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Verify dialog content
      expect(find.text('Confirmar eliminación'), findsOneWidget);
      expect(find.text("¿Eliminar 'My Portfolio App'?"), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
      expect(find.text('Eliminar'), findsOneWidget);
    });

    testWidgets('dismisses dialog when Cancel is tapped', (tester) async {
      final project = _makeProject();

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed
      expect(find.text('Confirmar eliminación'), findsNothing);
      // No deletion should have occurred
      verifyNever(() => mockProjectRepo.deleteProject(any()));
    });

    testWidgets('displays project title with special characters correctly',
        (tester) async {
      final project = _makeProject(title: "App's \"Best\" <Project>");

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text("¿Eliminar 'App's \"Best\" <Project>'?"),
        findsOneWidget,
      );
    });
  });

  group('DeleteProjectDialog - Successful Deletion', () {
    testWidgets('deletes project and images on confirm', (tester) async {
      final project = _makeProject(
        id: 'proj-42',
        mainImageUrl: 'https://example.com/main.png',
        additionalImageUrls: [
          'https://example.com/extra1.png',
          'https://example.com/extra2.png',
        ],
      );

      when(() => mockImageRepo.deleteImage(any()))
          .thenAnswer((_) async {});
      when(() => mockProjectRepo.deleteProject('proj-42'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Eliminar to confirm
      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Verify images were deleted
      verify(() => mockImageRepo.deleteImage('https://example.com/main.png'))
          .called(1);
      verify(() => mockImageRepo.deleteImage('https://example.com/extra1.png'))
          .called(1);
      verify(() => mockImageRepo.deleteImage('https://example.com/extra2.png'))
          .called(1);

      // Verify project was deleted
      verify(() => mockProjectRepo.deleteProject('proj-42')).called(1);

      // Dialog should be dismissed
      expect(find.text('Confirmar eliminación'), findsNothing);
    });

    testWidgets('deletes project even if image deletion fails',
        (tester) async {
      final project = _makeProject(
        id: 'proj-99',
        mainImageUrl: 'https://example.com/main.png',
      );

      when(() => mockImageRepo.deleteImage(any()))
          .thenThrow(Exception('Storage error'));
      when(() => mockProjectRepo.deleteProject('proj-99'))
          .thenAnswer((_) async {});

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Project should still be deleted even though image deletion failed
      verify(() => mockProjectRepo.deleteProject('proj-99')).called(1);
    });
  });

  group('DeleteProjectDialog - Failure Handling', () {
    testWidgets('shows error SnackBar when project deletion fails',
        (tester) async {
      final project = _makeProject(id: 'proj-fail');

      when(() => mockImageRepo.deleteImage(any()))
          .thenAnswer((_) async {});
      when(() => mockProjectRepo.deleteProject('proj-fail'))
          .thenThrow(Exception('Firestore error'));

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Error SnackBar should be shown
      expect(
        find.text('No se pudo eliminar el proyecto. Intente nuevamente.'),
        findsOneWidget,
      );
    });

    testWidgets('dialog is dismissed after failure (state preserved via stream)',
        (tester) async {
      final project = _makeProject(id: 'proj-fail-2');

      when(() => mockImageRepo.deleteImage(any()))
          .thenAnswer((_) async {});
      when(() => mockProjectRepo.deleteProject('proj-fail-2'))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Eliminar'));
      await tester.pumpAndSettle();

      // Dialog should be dismissed (project remains in list via StreamProvider)
      expect(find.text('Confirmar eliminación'), findsNothing);
    });
  });

  group('DeleteProjectDialog - Loading State', () {
    testWidgets('shows loading indicator while deleting', (tester) async {
      final project = _makeProject(id: 'proj-slow');

      when(() => mockImageRepo.deleteImage(any()))
          .thenAnswer((_) async {});
      // Use a delayed future to simulate slow deletion
      when(() => mockProjectRepo.deleteProject('proj-slow')).thenAnswer(
        (_) => Future.delayed(const Duration(seconds: 2)),
      );

      await tester.pumpWidget(_buildTestApp(
        project: project,
        projectRepo: mockProjectRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Tap Eliminar
      await tester.tap(find.text('Eliminar'));
      await tester.pump(); // Don't settle — let the future be pending

      // Should show a CircularProgressIndicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Buttons should be disabled (can't tap Cancel or Eliminar again)
      final cancelButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(cancelButton.onPressed, isNull);

      // Complete the future
      await tester.pumpAndSettle();
    });
  });
}
