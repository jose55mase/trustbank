import 'dart:async';
import 'dart:typed_data';

import 'package:delivery_app/portfolio/models/editable_content.dart';
import 'package:delivery_app/portfolio/providers/portfolio_providers.dart';
import 'package:delivery_app/portfolio/repositories/editable_content_repository.dart';
import 'package:delivery_app/portfolio/repositories/image_storage_repository.dart';
import 'package:delivery_app/portfolio/screens/content_editor_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// --- Mocks ---

class MockEditableContentRepository extends Mock
    implements EditableContentRepository {}

class MockImageStorageRepository extends Mock
    implements ImageStorageRepository {}

// --- Test data ---

final _heroContent = [
  EditableContent(
    id: 'hero-title',
    section: 'hero',
    key: 'title',
    value: 'Welcome to My Portfolio',
    type: ContentType.title,
    updatedAt: DateTime(2024, 1, 1),
  ),
  EditableContent(
    id: 'hero-subtitle',
    section: 'hero',
    key: 'subtitle',
    value: 'I build amazing software',
    type: ContentType.text,
    updatedAt: DateTime(2024, 1, 1),
  ),
  EditableContent(
    id: 'hero-image',
    section: 'hero',
    key: 'background',
    value: 'https://storage.example.com/hero.png',
    type: ContentType.image,
    updatedAt: DateTime(2024, 1, 1),
  ),
];

final _aboutContent = [
  EditableContent(
    id: 'about-title',
    section: 'about',
    key: 'title',
    value: 'About Me',
    type: ContentType.title,
    updatedAt: DateTime(2024, 1, 1),
  ),
  EditableContent(
    id: 'about-description',
    section: 'about',
    key: 'description',
    value: 'I am a software developer with 10 years of experience.',
    type: ContentType.text,
    updatedAt: DateTime(2024, 1, 1),
  ),
];

final _footerContent = [
  EditableContent(
    id: 'footer-copyright',
    section: 'footer',
    key: 'copyright',
    value: '© 2024 My Portfolio',
    type: ContentType.text,
    updatedAt: DateTime(2024, 1, 1),
  ),
];

// --- Helpers ---

Widget buildTestPanel({
  required MockEditableContentRepository contentRepo,
  required MockImageStorageRepository imageRepo,
  List<String>? sections,
}) {
  return ProviderScope(
    overrides: [
      contentRepositoryProvider.overrideWithValue(contentRepo),
      imageStorageProvider.overrideWithValue(imageRepo),
    ],
    child: MaterialApp(
      home: ContentEditorPanel(
        sections: sections,
      ),
    ),
  );
}

void main() {
  late MockEditableContentRepository mockContentRepo;
  late MockImageStorageRepository mockImageRepo;

  setUpAll(() {
    registerFallbackValue(EditableContent(
      id: '',
      section: '',
      key: '',
      value: '',
      type: ContentType.text,
      updatedAt: DateTime.now(),
    ));
    registerFallbackValue(Uint8List(0));
  });

  setUp(() {
    mockContentRepo = MockEditableContentRepository();
    mockImageRepo = MockImageStorageRepository();
  });

  group('ContentEditorPanel - Display', () {
    testWidgets('renders section headers for all sections', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value(_heroContent));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value(_aboutContent));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value(_footerContent));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Editar Contenido'), findsOneWidget);
      expect(find.text('Hero'), findsOneWidget);
      expect(find.text('Acerca de'), findsOneWidget);
      expect(find.text('Pie de página'), findsOneWidget);
    });

    testWidgets('displays content items with their values', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value(_heroContent));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value(_aboutContent));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value(_footerContent));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Hero content values
      expect(find.text('Welcome to My Portfolio'), findsOneWidget);
      expect(find.text('I build amazing software'), findsOneWidget);

      // About content values
      expect(find.text('About Me'), findsOneWidget);
      expect(
        find.text('I am a software developer with 10 years of experience.'),
        findsOneWidget,
      );
    });

    testWidgets('shows section/key labels for each item', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value(_heroContent));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('hero / title'), findsOneWidget);
      expect(find.text('hero / subtitle'), findsOneWidget);
      expect(find.text('hero / background'), findsOneWidget);
    });

    testWidgets('shows empty message for sections with no content',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      expect(
        find.text('No hay contenido en esta sección'),
        findsNWidgets(3),
      );
    });

    testWidgets('shows loading indicator while content loads', (tester) async {
      // Use a stream that never emits
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => const Stream.empty());
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => const Stream.empty());

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      // Don't pumpAndSettle — stream hasn't emitted yet
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsWidgets);
    });

    testWidgets('shows image items with replace button', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value(_heroContent));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reemplazar'), findsOneWidget);
    });

    testWidgets('supports custom sections list', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value(_heroContent));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
        sections: ['hero'],
      ));
      await tester.pumpAndSettle();

      expect(find.text('Hero'), findsOneWidget);
      // Other sections not shown
      expect(find.text('Acerca de'), findsNothing);
      expect(find.text('Pie de página'), findsNothing);
    });
  });

  group('ContentEditorPanel - Text Editing', () {
    testWidgets('tapping edit shows text field with current value',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Tap edit button
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // TextField should appear with current value
      expect(find.byType(TextField), findsOneWidget);
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Welcome to My Portfolio');

      // Save and Cancel buttons visible
      expect(find.text('Guardar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('cancel editing hides the text field', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Start editing
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      // TextField gone, original value shown
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Welcome to My Portfolio'), findsOneWidget);
    });

    testWidgets('saving valid content calls updateContent', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.updateContent(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Start editing
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Change the text
      await tester.enterText(find.byType(TextField), 'New Title');
      await tester.pumpAndSettle();

      // Save
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Verify updateContent was called
      verify(() => mockContentRepo.updateContent(any())).called(1);
    });

    testWidgets('shows validation error for empty content', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Start editing
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Clear the text
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Validation error shown
      expect(find.text('El contenido es requerido'), findsOneWidget);

      // updateContent NOT called
      verifyNever(() => mockContentRepo.updateContent(any()));
    });

    testWidgets('shows validation error for whitespace-only content',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Start editing
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Enter whitespace only
      await tester.enterText(find.byType(TextField), '   ');
      await tester.pumpAndSettle();

      // Try to save
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Validation error shown
      expect(find.text('El contenido es requerido'), findsOneWidget);

      // updateContent NOT called
      verifyNever(() => mockContentRepo.updateContent(any()));
    });

    testWidgets('shows error banner on save failure and preserves content',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[0]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.updateContent(any()))
          .thenThrow(Exception('Network error'));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Start editing
      await tester.tap(find.byIcon(Icons.edit));
      await tester.pumpAndSettle();

      // Change the text
      await tester.enterText(find.byType(TextField), 'Updated Content');
      await tester.pumpAndSettle();

      // Save (will fail)
      await tester.tap(find.text('Guardar'));
      await tester.pumpAndSettle();

      // Error message shown
      expect(
        find.text('No se pudo guardar el cambio. Intente de nuevo.'),
        findsOneWidget,
      );

      // Edited content preserved in the text field
      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, 'Updated Content');
    });
  });

  group('ContentEditorPanel - Image Replacement', () {
    testWidgets('replaceImage with invalid format shows error',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[2]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      // Get the state and call replaceImage with invalid format
      final panelState = tester.state<ContentEditorPanelState>(
        find.byType(ContentEditorPanel),
      );
      await panelState.replaceImage(
        _heroContent[2],
        Uint8List.fromList([1, 2, 3]),
        'image.gif',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Formato no soportado. Use PNG, JPG o WebP'),
        findsOneWidget,
      );
    });

    testWidgets('replaceImage with file > 5MB shows error', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[2]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      final panelState = tester.state<ContentEditorPanelState>(
        find.byType(ContentEditorPanel),
      );
      final largeBytes = Uint8List(6 * 1024 * 1024); // 6 MB
      await panelState.replaceImage(
        _heroContent[2],
        largeBytes,
        'large.png',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('La imagen no puede exceder 5 MB'),
        findsOneWidget,
      );
    });

    testWidgets('replaceImage with valid file uploads and updates content',
        (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[2]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockImageRepo.uploadImage(any(), any()))
          .thenAnswer((_) async => 'https://storage.example.com/new-hero.png');
      when(() => mockContentRepo.updateContent(any()))
          .thenAnswer((_) async {});

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      final panelState = tester.state<ContentEditorPanelState>(
        find.byType(ContentEditorPanel),
      );
      await panelState.replaceImage(
        _heroContent[2],
        Uint8List.fromList([1, 2, 3]),
        'new-hero.png',
      );
      await tester.pumpAndSettle();

      // Verify upload and update were called
      verify(() => mockImageRepo.uploadImage(any(), 'new-hero.png')).called(1);
      verify(() => mockContentRepo.updateContent(any())).called(1);
    });

    testWidgets('replaceImage shows error on upload failure', (tester) async {
      when(() => mockContentRepo.watchContentBySection('hero'))
          .thenAnswer((_) => Stream.value([_heroContent[2]]));
      when(() => mockContentRepo.watchContentBySection('about'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockContentRepo.watchContentBySection('footer'))
          .thenAnswer((_) => Stream.value([]));
      when(() => mockImageRepo.validateImage(any(), any()))
          .thenAnswer((_) async => true);
      when(() => mockImageRepo.uploadImage(any(), any()))
          .thenThrow(Exception('Upload failed'));

      await tester.pumpWidget(buildTestPanel(
        contentRepo: mockContentRepo,
        imageRepo: mockImageRepo,
      ));
      await tester.pumpAndSettle();

      final panelState = tester.state<ContentEditorPanelState>(
        find.byType(ContentEditorPanel),
      );
      await panelState.replaceImage(
        _heroContent[2],
        Uint8List.fromList([1, 2, 3]),
        'photo.png',
      );
      await tester.pumpAndSettle();

      expect(
        find.text('No se pudo guardar el cambio. Intente de nuevo.'),
        findsWidgets,
      );
    });
  });

  group('ContentEditorPanel - Static Validators', () {
    test('validateContentValue returns error for empty string', () {
      expect(ContentEditorPanel.validateContentValue(''), isNotNull);
      expect(ContentEditorPanel.validateContentValue('   '), isNotNull);
      expect(ContentEditorPanel.validateContentValue(null), isNotNull);
    });

    test('validateContentValue returns null for valid input', () {
      expect(ContentEditorPanel.validateContentValue('Hello'), isNull);
      expect(ContentEditorPanel.validateContentValue(' Valid '), isNull);
    });

    test('validateImageFile rejects unsupported formats', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(
          ContentEditorPanel.validateImageFile(bytes, 'image.gif'), isNotNull);
      expect(
          ContentEditorPanel.validateImageFile(bytes, 'image.bmp'), isNotNull);
      expect(
          ContentEditorPanel.validateImageFile(bytes, 'image.svg'), isNotNull);
    });

    test('validateImageFile accepts supported formats', () {
      final bytes = Uint8List.fromList([1, 2, 3]);
      expect(ContentEditorPanel.validateImageFile(bytes, 'image.png'), isNull);
      expect(ContentEditorPanel.validateImageFile(bytes, 'image.jpg'), isNull);
      expect(ContentEditorPanel.validateImageFile(bytes, 'image.jpeg'), isNull);
      expect(ContentEditorPanel.validateImageFile(bytes, 'image.webp'), isNull);
    });

    test('validateImageFile rejects files > 5MB', () {
      final largeBytes = Uint8List(6 * 1024 * 1024);
      expect(
        ContentEditorPanel.validateImageFile(largeBytes, 'big.png'),
        isNotNull,
      );
    });

    test('validateImageFile accepts files <= 5MB', () {
      final exactBytes = Uint8List(5 * 1024 * 1024);
      expect(
        ContentEditorPanel.validateImageFile(exactBytes, 'exact.png'),
        isNull,
      );
    });
  });
}
