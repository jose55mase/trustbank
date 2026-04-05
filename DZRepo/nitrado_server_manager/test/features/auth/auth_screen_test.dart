import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:nitrado_server_manager/core/storage/auth_service.dart';
import 'package:nitrado_server_manager/core/storage/auth_provider.dart';
import 'package:nitrado_server_manager/features/auth/auth_screen.dart';

class MockAuthService extends Mock implements AuthService {}

void main() {
  late MockAuthService mockAuthService;

  setUp(() {
    mockAuthService = MockAuthService();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [
        authServiceProvider.overrideWithValue(mockAuthService),
      ],
      child: const MaterialApp(home: AuthScreen()),
    );
  }

  group('AuthScreen', () {
    testWidgets('renders token field and button', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Token OAuth'), findsOneWidget);
      expect(find.text('Autenticar'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows validation error for empty token', (tester) async {
      await tester.pumpWidget(buildSubject());

      await tester.tap(find.text('Autenticar'));
      await tester.pumpAndSettle();

      expect(find.text('El token no puede estar vacío'), findsOneWidget);
    });

    testWidgets('shows error message for invalid token', (tester) async {
      when(() => mockAuthService.validateToken('bad-token'))
          .thenAnswer((_) async => false);

      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextFormField), 'bad-token');
      await tester.tap(find.text('Autenticar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('inválido'), findsOneWidget);
    });

    testWidgets('shows loading indicator during validation', (tester) async {
      final completer = Completer<bool>();
      when(() => mockAuthService.validateToken('slow-token'))
          .thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildSubject());

      await tester.enterText(find.byType(TextFormField), 'slow-token');
      await tester.tap(find.text('Autenticar'));
      await tester.pump(); // start the async call

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future so the timer is cleaned up.
      completer.complete(false);
      await tester.pumpAndSettle();
    });

    testWidgets('title and icon are displayed', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Nitrado Server Manager'), findsOneWidget);
      expect(find.byIcon(Icons.dns_rounded), findsOneWidget);
    });
  });
}
