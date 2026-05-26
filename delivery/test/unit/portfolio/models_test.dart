import 'package:flutter_test/flutter_test.dart';
import 'package:delivery_app/portfolio/models/models.dart';

void main() {
  group('PortfolioProject', () {
    test('toJson/fromJson round-trip preserves data', () {
      final now = DateTime(2024, 1, 15, 10, 30);
      final project = PortfolioProject(
        id: 'proj-1',
        title: 'Test Project',
        description: 'A test project description',
        mainImageUrl: 'https://example.com/image.png',
        additionalImageUrls: ['https://example.com/img2.png'],
        externalLink: 'https://github.com/test',
        technologies: ['Flutter', 'Dart'],
        isFeatured: true,
        createdAt: now,
        updatedAt: now,
      );

      final json = project.toJson();
      final restored = PortfolioProject.fromJson(json);

      expect(restored.id, project.id);
      expect(restored.title, project.title);
      expect(restored.description, project.description);
      expect(restored.mainImageUrl, project.mainImageUrl);
      expect(restored.additionalImageUrls, project.additionalImageUrls);
      expect(restored.externalLink, project.externalLink);
      expect(restored.technologies, project.technologies);
      expect(restored.isFeatured, project.isFeatured);
      expect(restored.createdAt, project.createdAt);
      expect(restored.updatedAt, project.updatedAt);
    });

    test('fromJson handles missing optional fields', () {
      final json = {
        'id': 'proj-2',
        'title': 'Minimal Project',
        'description': 'Desc',
        'mainImageUrl': 'https://example.com/img.png',
        'createdAt': '2024-01-15T10:30:00.000',
        'updatedAt': '2024-01-15T10:30:00.000',
      };

      final project = PortfolioProject.fromJson(json);

      expect(project.additionalImageUrls, isEmpty);
      expect(project.externalLink, isNull);
      expect(project.technologies, isEmpty);
      expect(project.isFeatured, false);
    });

    test('copyWith creates modified copy', () {
      final now = DateTime(2024, 1, 15);
      final project = PortfolioProject(
        id: 'proj-1',
        title: 'Original',
        description: 'Desc',
        mainImageUrl: 'https://example.com/img.png',
        createdAt: now,
        updatedAt: now,
      );

      final modified = project.copyWith(title: 'Modified', isFeatured: true);

      expect(modified.title, 'Modified');
      expect(modified.isFeatured, true);
      expect(modified.id, project.id);
      expect(modified.description, project.description);
    });
  });

  group('CarouselItem', () {
    test('toJson/fromJson round-trip preserves data', () {
      final item = CarouselItem(
        projectId: 'proj-1',
        title: 'Carousel Title',
        description: 'Carousel description text',
        imageUrl: 'https://example.com/carousel.png',
        order: 2,
      );

      final json = item.toJson();
      final restored = CarouselItem.fromJson(json);

      expect(restored.projectId, item.projectId);
      expect(restored.title, item.title);
      expect(restored.description, item.description);
      expect(restored.imageUrl, item.imageUrl);
      expect(restored.order, item.order);
    });

    test('equality works correctly', () {
      final item1 = CarouselItem(
        projectId: 'proj-1',
        title: 'Title',
        description: 'Desc',
        imageUrl: 'https://example.com/img.png',
        order: 1,
      );
      final item2 = CarouselItem(
        projectId: 'proj-1',
        title: 'Title',
        description: 'Desc',
        imageUrl: 'https://example.com/img.png',
        order: 1,
      );

      expect(item1, equals(item2));
    });
  });

  group('EditableContent', () {
    test('toJson/fromJson round-trip preserves data', () {
      final content = EditableContent(
        id: 'content-1',
        section: 'hero',
        key: 'title',
        value: 'Welcome to my portfolio',
        type: ContentType.title,
        updatedAt: DateTime(2024, 3, 10),
      );

      final json = content.toJson();
      final restored = EditableContent.fromJson(json);

      expect(restored.id, content.id);
      expect(restored.section, content.section);
      expect(restored.key, content.key);
      expect(restored.value, content.value);
      expect(restored.type, content.type);
      expect(restored.updatedAt, content.updatedAt);
    });

    test('ContentType enum serializes correctly', () {
      for (final type in ContentType.values) {
        final content = EditableContent(
          id: 'c-1',
          section: 'test',
          key: 'k',
          value: 'v',
          type: type,
          updatedAt: DateTime(2024, 1, 1),
        );

        final json = content.toJson();
        final restored = EditableContent.fromJson(json);
        expect(restored.type, type);
      }
    });
  });

  group('PortfolioAuthState', () {
    test('toJson/fromJson round-trip preserves data', () {
      final state = PortfolioAuthState(
        isAuthenticated: true,
        failedAttempts: 3,
        lockoutUntil: DateTime(2024, 6, 1, 12, 0),
        redirectAfterLogin: '/portfolio/admin/projects',
      );

      final json = state.toJson();
      final restored = PortfolioAuthState.fromJson(json);

      expect(restored.isAuthenticated, state.isAuthenticated);
      expect(restored.failedAttempts, state.failedAttempts);
      expect(restored.lockoutUntil, state.lockoutUntil);
      expect(restored.redirectAfterLogin, state.redirectAfterLogin);
    });

    test('fromJson handles null optional fields', () {
      final json = <String, dynamic>{
        'isAuthenticated': false,
        'failedAttempts': 0,
      };

      final state = PortfolioAuthState.fromJson(json);

      expect(state.isAuthenticated, false);
      expect(state.failedAttempts, 0);
      expect(state.lockoutUntil, isNull);
      expect(state.redirectAfterLogin, isNull);
    });

    test('isLockedOut returns true when lockout is in the future', () {
      final state = PortfolioAuthState(
        lockoutUntil: DateTime.now().add(const Duration(minutes: 10)),
      );

      expect(state.isLockedOut, true);
    });

    test('isLockedOut returns false when lockout is in the past', () {
      final state = PortfolioAuthState(
        lockoutUntil: DateTime.now().subtract(const Duration(minutes: 1)),
      );

      expect(state.isLockedOut, false);
    });

    test('default state is unauthenticated with zero attempts', () {
      const state = PortfolioAuthState();

      expect(state.isAuthenticated, false);
      expect(state.failedAttempts, 0);
      expect(state.lockoutUntil, isNull);
      expect(state.redirectAfterLogin, isNull);
    });
  });

  group('OperationResult', () {
    test('Success holds data', () {
      const result = Success<String>('project saved');

      expect(result.data, 'project saved');
      expect(result, isA<OperationResult<String>>());
    });

    test('Failure holds message and type', () {
      const result = Failure<String>('Network error', FailureType.network);

      expect(result.message, 'Network error');
      expect(result.type, FailureType.network);
      expect(result, isA<OperationResult<String>>());
    });

    test('sealed class pattern matching works', () {
      final OperationResult<int> success = const Success(42);
      final OperationResult<int> failure =
          const Failure('failed', FailureType.unknown);

      final successValue = switch (success) {
        Success<int>(:final data) => data,
        Failure<int>() => -1,
      };

      final failureValue = switch (failure) {
        Success<int>() => -1,
        Failure<int>(:final message) => message,
      };

      expect(successValue, 42);
      expect(failureValue, 'failed');
    });

    test('FailureType enum has all expected values', () {
      expect(FailureType.values, containsAll([
        FailureType.network,
        FailureType.validation,
        FailureType.authentication,
        FailureType.storage,
        FailureType.unknown,
      ]));
    });
  });
}
