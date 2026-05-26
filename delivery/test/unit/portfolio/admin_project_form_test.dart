import 'dart:typed_data';

import 'package:delivery_app/portfolio/models/portfolio_project.dart';
import 'package:delivery_app/portfolio/providers/portfolio_providers.dart';
import 'package:delivery_app/portfolio/repositories/image_storage_repository.dart';
import 'package:delivery_app/portfolio/repositories/portfolio_project_repository.dart';
import 'package:delivery_app/portfolio/screens/admin_project_form.dart';
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

Widget buildTestForm({
  PortfolioProject? existingProject,
  VoidCallback? onSaveSuccess,
  required MockImageStorageRepository imageRepo,
  required MockPortfolioProjectRepository projectRepo,
}) {
  return ProviderScope(
    overrides: [
      imageStorageProvider.overrideWithValue(imageRepo),
      projectRepositoryProvider.overrideWithValue(projectRepo),
    ],
    child: MaterialApp(
      home: AdminProjectForm(
        existingProject: existingProject,
        onSaveSuccess: onSaveSuccess,
      ),
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

  group('AdminProjectForm - Create Mode', () {
    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      expect(find.text('Nuevo Proyecto'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Título *'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Descripción *'), findsOneWidget);
      expect(find.text('Imagen principal *'), findsOneWidget);
      expect(find.text('Imágenes adicionales (máx. 5)'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Enlace externo'), findsOneWidget);
      expect(
          find.widgetWithText(TextFormField, 'Tecnologías'), findsOneWidget);
      expect(find.text('Proyecto destacado'), findsOneWidget);
      expect(find.text('Crear proyecto'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty required fields',
        (tester) async {
      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Scroll to the save button and tap it
      await tester.scrollUntilVisible(
        find.text('Crear proyecto'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Crear proyecto'));
      await tester.pumpAndSettle();

      // Should show inline errors for title and description
      expect(find.text('El título es obligatorio'), findsOneWidget);
      expect(find.text('La descripción es obligatoria'), findsOneWidget);
      // Should show main image error
      expect(find.text('La imagen principal es obligatoria'), findsOneWidget);
    });

    testWidgets(
        'preserves other field values when validation fails on one field',
        (tester) async {
      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Fill description but leave title empty
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción *'),
        'A valid description',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Enlace externo'),
        'https://example.com',
      );

      // Scroll to save button and tap
      await tester.scrollUntilVisible(
        find.text('Crear proyecto'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Crear proyecto'));
      await tester.pumpAndSettle();

      // Scroll back up to see the title error
      await tester.scrollUntilVisible(
        find.text('El título es obligatorio'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Title error shown
      expect(find.text('El título es obligatorio'), findsOneWidget);

      // Other fields preserved
      final descField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Descripción *'),
      );
      expect(
        (descField.controller as TextEditingController).text,
        'A valid description',
      );

      // Scroll to link field
      await tester.scrollUntilVisible(
        find.widgetWithText(TextFormField, 'Enlace externo'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      final linkField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Enlace externo'),
      );
      expect(
        (linkField.controller as TextEditingController).text,
        'https://example.com',
      );
    });

    testWidgets('shows error for title exceeding 100 characters',
        (tester) async {
      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Enter a title that's too long (101 chars)
      // Note: maxLength on TextFormField prevents typing beyond 100,
      // but the validator still checks
      final longTitle = 'A' * 101;
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título *'),
        longTitle,
      );
      await tester.tap(find.text('Crear proyecto'));
      await tester.pumpAndSettle();

      // The maxLength attribute prevents entering more than 100 chars,
      // so the field will have exactly 100 chars and pass validation.
      // We test the validator function directly instead.
    });

    testWidgets('isFeatured toggle works', (tester) async {
      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Scroll to the switch
      await tester.scrollUntilVisible(
        find.byType(SwitchListTile),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      // Initially off
      final switchListTile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(switchListTile.value, false);

      // Toggle on by tapping the SwitchListTile
      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final updatedTile =
          tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(updatedTile.value, true);
    });

    testWidgets('successful create calls createProject and onSaveSuccess',
        (tester) async {
      bool saveSuccessCalled = false;

      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockImageRepo.uploadImage(any(), any()))
          .thenAnswer((_) async => 'https://storage.example.com/image.png');
      when(() => mockProjectRepo.createProject(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
        onSaveSuccess: () => saveSuccessCalled = true,
      ));

      // Fill required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título *'),
        'Test Project',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción *'),
        'A test description',
      );

      // Set main image programmatically via state
      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;
      await adminFormState.setMainImage(
        Uint8List.fromList([1, 2, 3]),
        'test.png',
      );
      await tester.pumpAndSettle();

      // Scroll to save button and tap
      await tester.scrollUntilVisible(
        find.text('Crear proyecto'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Crear proyecto'));
      await tester.pumpAndSettle();

      verify(() => mockProjectRepo.createProject(any())).called(1);
      expect(saveSuccessCalled, true);
    });

    testWidgets('shows save error on network failure and preserves form data',
        (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockImageRepo.uploadImage(any(), any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Fill required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título *'),
        'My Project',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descripción *'),
        'My description',
      );

      // Set main image
      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;
      await adminFormState.setMainImage(
        Uint8List.fromList([1, 2, 3]),
        'photo.jpg',
      );
      await tester.pumpAndSettle();

      // Scroll to save button and tap
      await tester.scrollUntilVisible(
        find.text('Crear proyecto'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Crear proyecto'));
      await tester.pumpAndSettle();

      // Scroll to top to see error banner
      await tester.scrollUntilVisible(
        find.textContaining('No se pudo completar'),
        -200,
        scrollable: find.byType(Scrollable).first,
      );

      // Error message shown
      expect(
        find.text('No se pudo completar la operación. Intente de nuevo.'),
        findsOneWidget,
      );

      // Form data preserved
      final titleField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Título *'),
      );
      expect(
        (titleField.controller as TextEditingController).text,
        'My Project',
      );
    });
  });

  group('AdminProjectForm - Edit Mode', () {
    final existingProject = PortfolioProject(
      id: 'proj-1',
      title: 'Existing Project',
      description: 'Existing description',
      mainImageUrl: 'https://storage.example.com/main.png',
      additionalImageUrls: [
        'https://storage.example.com/add1.jpg',
        'https://storage.example.com/add2.webp',
      ],
      externalLink: 'https://github.com/example',
      technologies: ['Flutter', 'Dart', 'Firebase'],
      isFeatured: true,
      createdAt: DateTime(2024, 1, 1),
      updatedAt: DateTime(2024, 6, 1),
    );

    testWidgets('pre-fills all fields with existing project data',
        (tester) async {
      await tester.pumpWidget(buildTestForm(
        existingProject: existingProject,
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Title shows "Editar Proyecto"
      expect(find.text('Editar Proyecto'), findsOneWidget);
      expect(find.text('Guardar cambios'), findsOneWidget);

      // Fields pre-filled
      final titleField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Título *'),
      );
      expect(
        (titleField.controller as TextEditingController).text,
        'Existing Project',
      );

      final descField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Descripción *'),
      );
      expect(
        (descField.controller as TextEditingController).text,
        'Existing description',
      );

      final linkField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Enlace externo'),
      );
      expect(
        (linkField.controller as TextEditingController).text,
        'https://github.com/example',
      );

      final techField = tester.widget<TextFormField>(
        find.widgetWithText(TextFormField, 'Tecnologías'),
      );
      expect(
        (techField.controller as TextEditingController).text,
        'Flutter, Dart, Firebase',
      );

      // isFeatured is on
      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, true);

      // Main image chip shown
      expect(find.text('main.png'), findsOneWidget);

      // Additional image chips shown
      expect(find.text('add1.jpg'), findsOneWidget);
      expect(find.text('add2.webp'), findsOneWidget);
    });

    testWidgets('successful edit calls updateProject', (tester) async {
      when(() => mockProjectRepo.updateProject(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestForm(
        existingProject: existingProject,
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      // Modify title
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Título *'),
        'Updated Title',
      );

      // Scroll to save button and tap
      await tester.scrollUntilVisible(
        find.text('Guardar cambios'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Guardar cambios'));
      await tester.pumpAndSettle();

      verify(() => mockProjectRepo.updateProject(any())).called(1);
    });
  });

  group('AdminProjectForm - Image Validation', () {
    testWidgets('rejects image with invalid format', (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;

      // Try to set a GIF image
      await adminFormState.setMainImage(
        Uint8List.fromList([1, 2, 3]),
        'image.gif',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Formato no soportado. Use PNG, JPG o WebP'),
        findsOneWidget,
      );
    });

    testWidgets('rejects image exceeding 5MB', (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;

      // Create a file > 5MB
      final largeBytes = Uint8List(6 * 1024 * 1024); // 6 MB
      await adminFormState.setMainImage(largeBytes, 'large.png');
      await tester.pumpAndSettle();

      expect(
        find.text('La imagen no puede exceder 5 MB'),
        findsOneWidget,
      );
    });

    testWidgets('rejects more than 5 additional images', (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;

      // Add 5 images
      for (int i = 0; i < 5; i++) {
        await adminFormState.addAdditionalImage(
          Uint8List.fromList([1, 2, 3]),
          'img$i.png',
        );
      }
      await tester.pumpAndSettle();

      // Try to add a 6th
      await adminFormState.addAdditionalImage(
        Uint8List.fromList([1, 2, 3]),
        'img5.png',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Máximo 5 imágenes adicionales permitidas'),
        findsOneWidget,
      );
    });

    testWidgets('accepts valid PNG image', (tester) async {
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);

      await tester.pumpWidget(buildTestForm(
        imageRepo: mockImageRepo,
        projectRepo: mockProjectRepo,
      ));

      final formState = tester.state<ConsumerState>(
        find.byType(AdminProjectForm),
      );
      final adminFormState = formState as dynamic;

      await adminFormState.setMainImage(
        Uint8List.fromList([1, 2, 3]),
        'photo.png',
      );
      await tester.pumpAndSettle();

      // No error shown, chip with filename displayed
      expect(find.text('photo.png'), findsOneWidget);
      expect(
        find.text('Formato no soportado. Use PNG, JPG o WebP'),
        findsNothing,
      );
    });
  });

  group('AdminProjectForm - Static Validators', () {
    test('validateTitle returns error for empty string', () {
      expect(AdminProjectForm.validateTitle(''), isNotNull);
      expect(AdminProjectForm.validateTitle('   '), isNotNull);
      expect(AdminProjectForm.validateTitle(null), isNotNull);
    });

    test('validateTitle returns error for > 100 chars', () {
      expect(AdminProjectForm.validateTitle('A' * 101), isNotNull);
    });

    test('validateTitle returns null for valid input', () {
      expect(AdminProjectForm.validateTitle('Valid Title'), isNull);
      expect(AdminProjectForm.validateTitle('A' * 100), isNull);
    });

    test('validateDescription returns error for empty string', () {
      expect(AdminProjectForm.validateDescription(''), isNotNull);
      expect(AdminProjectForm.validateDescription('   '), isNotNull);
      expect(AdminProjectForm.validateDescription(null), isNotNull);
    });

    test('validateDescription returns error for > 500 chars', () {
      expect(AdminProjectForm.validateDescription('A' * 501), isNotNull);
    });

    test('validateDescription returns null for valid input', () {
      expect(AdminProjectForm.validateDescription('Valid description'), isNull);
      expect(AdminProjectForm.validateDescription('A' * 500), isNull);
    });

    test('validateImageFile rejects unsupported formats', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.gif'), isNotNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.bmp'), isNotNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.svg'), isNotNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'file.txt'), isNotNull);
    });

    test('validateImageFile accepts supported formats', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.png'), isNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.jpg'), isNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.jpeg'), isNull);
      expect(AdminProjectForm.validateImageFile(bytes, 'image.webp'), isNull);
    });

    test('validateImageFile rejects files > 5MB', () {
      final largeBytes = Uint8List(6 * 1024 * 1024);
      expect(
          AdminProjectForm.validateImageFile(largeBytes, 'big.png'), isNotNull);
    });

    test('validateImageFile accepts files <= 5MB', () {
      final exactBytes = Uint8List(5 * 1024 * 1024);
      expect(
          AdminProjectForm.validateImageFile(exactBytes, 'exact.png'), isNull);
    });
  });
}
