import 'dart:typed_data';

import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/providers/portfolio_providers.dart';
import 'package:delivery_app/portfolio/repositories/image_storage_repository.dart';
import 'package:delivery_app/portfolio/repositories/portfolio_project_repository.dart';
import 'package:delivery_app/portfolio/screens/carousel_content_editor.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockImageStorageRepository extends Mock
    implements ImageStorageRepository {}

class MockPortfolioProjectRepository extends Mock
    implements PortfolioProjectRepository {}

// --- Test helpers ---

final _featuredProjects = [
  PortfolioProject(
    id: 'proj-1',
    title: 'Featured Project 1',
    description: 'Description for project 1',
    mainImageUrl: 'https://example.com/img1.png',
    isFeatured: true,
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 1),
  ),
  PortfolioProject(
    id: 'proj-2',
    title: 'Featured Project 2',
    description: 'Description for project 2',
    mainImageUrl: 'https://example.com/img2.png',
    isFeatured: true,
    createdAt: DateTime(2024, 2, 1),
    updatedAt: DateTime(2024, 6, 1),
  ),
];

Widget buildTestEditor({
  required MockImageStorageRepository imageRepo,
  required MockPortfolioProjectRepository projectRepo,
  List<PortfolioProject>? projects,
}) {
  final projectList = projects ?? _featuredProjects;

  return ProviderScope(
    overrides: [
      imageStorageProvider.overrideWithValue(imageRepo),
      projectRepositoryProvider.overrideWithValue(projectRepo),
      featuredProjectsProvider.overrideWith(
        (ref) => Stream.value(projectList),
      ),
    ],
    child: const MaterialApp(
      home: CarouselContentEditor(),
    ),
  );
}

void main() {
  late MockImageStorageRepository mockImageRepo;
  late MockPortfolioProjectRepository mockProjectRepo;

  setUpAll(() {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(PortfolioProject(
      id: '',
      title: '',
      description: '',
      mainImageUrl: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ));
  });

  setUp(() {
    mockImageRepo = MockImageStorageRepository();
    mockProjectRepo = MockPortfolioProjectRepository();
  });

  group('CarouselContentEditor - Static Validators', () {
    group('validateTitle', () {
      test('returns error for null', () {
        expect(CarouselContentEditor.validateTitle(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(CarouselContentEditor.validateTitle(''), isNotNull);
        expect(
          CarouselContentEditor.validateTitle(''),
          'El título es obligatorio',
        );
      });

      test('returns error for whitespace-only string', () {
        expect(CarouselContentEditor.validateTitle('   '), isNotNull);
        expect(
          CarouselContentEditor.validateTitle('   '),
          'El título es obligatorio',
        );
      });

      test('returns error for string exceeding 100 characters', () {
        final longTitle = 'A' * 101;
        expect(CarouselContentEditor.validateTitle(longTitle), isNotNull);
        expect(
          CarouselContentEditor.validateTitle(longTitle),
          'El título no puede exceder 100 caracteres',
        );
      });

      test('returns null for valid title at exactly 100 characters', () {
        final exactTitle = 'A' * 100;
        expect(CarouselContentEditor.validateTitle(exactTitle), isNull);
      });

      test('returns null for valid title under 100 characters', () {
        expect(CarouselContentEditor.validateTitle('Valid Title'), isNull);
        expect(CarouselContentEditor.validateTitle('A'), isNull);
      });
    });

    group('validateDescription', () {
      test('returns error for null', () {
        expect(CarouselContentEditor.validateDescription(null), isNotNull);
      });

      test('returns error for empty string', () {
        expect(CarouselContentEditor.validateDescription(''), isNotNull);
        expect(
          CarouselContentEditor.validateDescription(''),
          'La descripción es obligatoria',
        );
      });

      test('returns error for whitespace-only string', () {
        expect(CarouselContentEditor.validateDescription('   '), isNotNull);
        expect(
          CarouselContentEditor.validateDescription('   '),
          'La descripción es obligatoria',
        );
      });

      test('returns error for string exceeding 300 characters', () {
        final longDesc = 'B' * 301;
        expect(
            CarouselContentEditor.validateDescription(longDesc), isNotNull);
        expect(
          CarouselContentEditor.validateDescription(longDesc),
          'La descripción no puede exceder 300 caracteres',
        );
      });

      test('returns null for valid description at exactly 300 characters', () {
        final exactDesc = 'B' * 300;
        expect(CarouselContentEditor.validateDescription(exactDesc), isNull);
      });

      test('returns null for valid description under 300 characters', () {
        expect(
          CarouselContentEditor.validateDescription('Valid description'),
          isNull,
        );
        expect(CarouselContentEditor.validateDescription('B'), isNull);
      });
    });

    group('validateImageFile', () {
      test('rejects unsupported formats', () {
        final bytes = Uint8List.fromList([1, 2, 3]);
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.gif'),
          isNotNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.bmp'),
          isNotNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.svg'),
          isNotNull,
        );
      });

      test('accepts supported formats', () {
        final bytes = Uint8List.fromList([1, 2, 3]);
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.png'),
          isNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.jpg'),
          isNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.jpeg'),
          isNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(bytes, 'image.webp'),
          isNull,
        );
      });

      test('rejects files exceeding 5MB', () {
        final largeBytes = Uint8List(6 * 1024 * 1024);
        expect(
          CarouselContentEditor.validateImageFile(largeBytes, 'big.png'),
          isNotNull,
        );
        expect(
          CarouselContentEditor.validateImageFile(largeBytes, 'big.png'),
          'La imagen no puede exceder 5 MB',
        );
      });

      test('accepts files at exactly 5MB', () {
        final exactBytes = Uint8List(5 * 1024 * 1024);
        expect(
          CarouselContentEditor.validateImageFile(exactBytes, 'exact.png'),
          isNull,
        );
      });
    });
  });

  group('CarouselContentEditor - Widget Tests', () {
    testWidgets('displays featured projects list', (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Editar Carrusel'), findsOneWidget);
      expect(find.text('Elementos del Carrusel (2)'), findsOneWidget);
      // Use findsWidgets since the title may appear in multiple places
      expect(find.text('Featured Project 1'), findsWidgets);
      expect(find.text('Featured Project 2'), findsWidgets);
    });

    testWidgets('shows empty state when no featured projects', (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
        projects: [],
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay proyectos destacados para el carrusel'),
        findsOneWidget,
      );
    });

    testWidgets('enters edit mode when edit button is tapped', (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Tap the first edit button
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Should show editing fields
      expect(
        find.text('Título (máx. 100 caracteres)'),
        findsOneWidget,
      );
      expect(
        find.text('Descripción (máx. 300 caracteres)'),
        findsOneWidget,
      );
    });

    testWidgets('pre-fills fields with current project data in edit mode',
        (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Tap edit on first project
      await tester.tap(find.byIcon(Icons.edit).first);
      await tester.pumpAndSettle();

      // Find the TextField widgets and check their controllers
      final textFields = find.byType(TextField);
      // First TextField is title, second is description
      final titleTextField = tester.widget<TextField>(textFields.at(0));
      expect(titleTextField.controller?.text, 'Featured Project 1');

      final descTextField = tester.widget<TextField>(textFields.at(1));
      expect(descTextField.controller?.text, 'Description for project 1');
    });

    testWidgets('shows title validation error for empty title on save',
        (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via state to avoid scroll issues
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );
      editorState.startEditing(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Clear the title field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), '');
      await tester.pumpAndSettle();

      // Call save directly via state to avoid scroll issues
      await editorState.saveContent(_featuredProjects[0]);
      await tester.pumpAndSettle();

      expect(find.text('El título es obligatorio'), findsOneWidget);
    });

    testWidgets('shows description validation error for empty description on save',
        (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via state
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );
      editorState.startEditing(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Clear the description field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(1), '');
      await tester.pumpAndSettle();

      // Call save directly
      await editorState.saveContent(_featuredProjects[0]);
      await tester.pumpAndSettle();

      expect(find.text('La descripción es obligatoria'), findsOneWidget);
    });

    testWidgets('cancel editing returns to display mode', (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via state
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );
      editorState.startEditing(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Verify we're in edit mode
      expect(find.text('Título (máx. 100 caracteres)'), findsOneWidget);

      // Cancel via state
      editorState.cancelEditing();
      await tester.pumpAndSettle();

      // Should be back in display mode
      expect(find.text('Título (máx. 100 caracteres)'), findsNothing);
      expect(find.text('Descripción (máx. 300 caracteres)'), findsNothing);
    });

    testWidgets('successful save calls updateProject', (tester) async {
      when(() => mockProjectRepo.updateProject(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via state
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );
      editorState.startEditing(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Modify title via text field
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'Updated Title');
      await tester.pumpAndSettle();

      // Save via state
      await editorState.saveContent(_featuredProjects[0]);
      await tester.pumpAndSettle();

      verify(() => mockProjectRepo.updateProject(any())).called(1);
    });

    testWidgets('shows save error on failure and preserves form data',
        (tester) async {
      when(() => mockProjectRepo.updateProject(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Enter edit mode via state
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );
      editorState.startEditing(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Modify title
      final textFields = find.byType(TextField);
      await tester.enterText(textFields.at(0), 'New Title');
      await tester.pumpAndSettle();

      // Save via state (will fail)
      await editorState.saveContent(_featuredProjects[0]);
      await tester.pumpAndSettle();

      // Error shown - scroll to find it
      expect(
        find.text('No se pudo guardar el cambio. Intente de nuevo.'),
        findsOneWidget,
      );

      // Still in edit mode (form data preserved)
      expect(find.text('Título (máx. 100 caracteres)'), findsOneWidget);
    });

    testWidgets('image replacement rejects invalid format', (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      // Access state to call replaceImage programmatically
      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );

      await editorState.replaceImage(
        _featuredProjects[0],
        Uint8List.fromList([1, 2, 3]),
        'image.gif',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Formato no soportado. Use PNG, JPG o WebP'),
        findsOneWidget,
      );
    });

    testWidgets('image replacement rejects file exceeding 5MB',
        (tester) async {
      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );

      final largeBytes = Uint8List(6 * 1024 * 1024);
      await editorState.replaceImage(
        _featuredProjects[0],
        largeBytes,
        'large.png',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('La imagen no puede exceder 5 MB'),
        findsOneWidget,
      );
    });

    testWidgets(
        'successful image replacement calls uploadImage and updateProject',
        (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockImageRepo.uploadImage(any(), any()))
          .thenAnswer((_) async => 'https://storage.example.com/new.png');
      when(() => mockProjectRepo.updateProject(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestEditor(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));
      await tester.pumpAndSettle();

      final editorState = tester.state<CarouselContentEditorState>(
        find.byType(CarouselContentEditor),
      );

      await editorState.replaceImage(
        _featuredProjects[0],
        Uint8List.fromList([1, 2, 3]),
        'new_image.png',
      );
      await tester.pumpAndSettle();

      verify(() => mockImageRepo.uploadImage(any(), any())).called(1);
      verify(() => mockProjectRepo.updateProject(any())).called(1);
    });
  });
}
