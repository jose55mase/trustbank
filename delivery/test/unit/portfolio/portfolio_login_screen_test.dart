import 'dart:async';

import 'package:delivery_app/portfolio/providers/portfolio_auth_notifier.dart';
import 'package:delivery_app/portfolio/providers/portfolio_providers.dart';
import 'package:delivery_app/portfolio/screens/portfolio_login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUserCredential extends Mock implements UserCredential {}

/// A testable wrapper that provides GoRouter and Riverpod context.
Widget buildTestApp({
  required MockFirebaseAuth mockAuth,
  String initialLocation = '/portfolio/admin/login',
  PortfolioAuthNotifier? notifier,
}) {
  final authNotifier = notifier ?? PortfolioAuthNotifier(mockAuth);

  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/portfolio/admin/login',
        builder: (context, state) => const PortfolioLoginScreen(),
      ),
      GoRoute(
        path: '/portfolio/admin',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Admin Dashboard')),
        ),
      ),
      GoRoute(
        path: '/portfolio/admin/projects',
        builder: (context, state) => const Scaffold(
          body: Center(child: Text('Admin Projects')),
        ),
      ),
    ],
  );

  return ProviderScope(
    overrides: [
      portfolioAuthProvider.overrideWith((_) => authNotifier),
    ],
    child: MaterialApp.router(
      routerConfig: router,
    ),
  );
}

void main() {
  late MockFirebaseAuth mockAuth;
  late MockUserCredential mockCredential;

  setUp(() {
    mockAuth = MockFirebaseAuth();
    mockCredential = MockUserCredential();
  });

  void mockSignInSuccess() {
    when(() => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => mockCredential);
  }

  void mockSignInFailure() {
    when(() => mockAuth.signInWithEmailAndPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenThrow(FirebaseAuthException(code: 'invalid-credential'));
  }

  group('PortfolioLoginScreen - UI Elements', () {
    testWidgets('displays title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Panel Administrativo'), findsOneWidget);
      expect(
        find.text('Inicia sesión para gestionar tu portafolio'),
        findsOneWidget,
      );
    });

    testWidgets('displays email and password fields', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Correo electrónico'), findsOneWidget);
      expect(find.text('Contraseña'), findsOneWidget);
    });

    testWidgets('displays login button', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      expect(find.text('Iniciar sesión'), findsOneWidget);
    });

    testWidgets('password field is obscured', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Find the EditableText inside the password field and check obscureText
      final editableTexts = find.byType(EditableText);
      final obscuredFields = editableTexts.evaluate().where((element) {
        final widget = element.widget as EditableText;
        return widget.obscureText;
      });
      expect(obscuredFields.length, 1);
    });
  });

  group('PortfolioLoginScreen - Form Validation', () {
    testWidgets('shows error when email is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Tap login without entering anything
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese su correo electrónico'), findsOneWidget);
    });

    testWidgets('shows error when password is empty', (tester) async {
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Enter email but not password
      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese su contraseña'), findsOneWidget);
    });

    testWidgets('does not show validation errors when fields are filled',
        (tester) async {
      mockSignInSuccess();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Ingrese su correo electrónico'), findsNothing);
      expect(find.text('Ingrese su contraseña'), findsNothing);
    });
  });

  group('PortfolioLoginScreen - Login Failure', () {
    testWidgets('shows generic error message on failed login', (tester) async {
      mockSignInFailure();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Credenciales incorrectas'), findsOneWidget);
    });

    testWidgets('error message does not reveal which field is wrong',
        (tester) async {
      mockSignInFailure();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'wrong@email.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'wrongpassword',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      // Only generic message, no field-specific hints
      expect(find.text('Credenciales incorrectas'), findsOneWidget);
      expect(find.textContaining('usuario incorrecto'), findsNothing);
      expect(find.textContaining('contraseña incorrecta'), findsNothing);
      expect(find.textContaining('no existe'), findsNothing);
    });
  });

  group('PortfolioLoginScreen - Lockout', () {
    testWidgets('shows lockout message after 5 failed attempts',
        (tester) async {
      mockSignInFailure();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Perform 5 failed login attempts
      for (var i = 0; i < 5; i++) {
        await tester.enterText(
          find.byType(TextFormField).first,
          'user@test.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'wrong',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
      }

      // Should show lockout message with countdown
      expect(find.textContaining('Cuenta bloqueada'), findsOneWidget);
    });

    testWidgets('disables form fields when locked out', (tester) async {
      mockSignInFailure();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      // Trigger lockout
      for (var i = 0; i < 5; i++) {
        await tester.enterText(
          find.byType(TextFormField).first,
          'user@test.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'wrong',
        );
        await tester.tap(find.text('Iniciar sesión'));
        await tester.pumpAndSettle();
      }

      // Login button should be disabled
      final button = tester.widget<ElevatedButton>(
        find.byType(ElevatedButton),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('PortfolioLoginScreen - Successful Login', () {
    testWidgets('navigates to admin dashboard on success', (tester) async {
      mockSignInSuccess();
      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Dashboard'), findsOneWidget);
    });

    testWidgets('navigates to returnTo path after login', (tester) async {
      mockSignInSuccess();

      final authNotifier = PortfolioAuthNotifier(mockAuth);
      // Pre-set the redirect path (simulating what the screen does from URL)
      authNotifier.setRedirectAfterLogin('/portfolio/admin/projects');

      final router = GoRouter(
        initialLocation: '/portfolio/admin/login',
        routes: [
          GoRoute(
            path: '/portfolio/admin/login',
            builder: (context, state) => const PortfolioLoginScreen(),
          ),
          GoRoute(
            path: '/portfolio/admin',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Dashboard')),
            ),
          ),
          GoRoute(
            path: '/portfolio/admin/projects',
            builder: (context, state) => const Scaffold(
              body: Center(child: Text('Admin Projects')),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            portfolioAuthProvider.overrideWith((_) => authNotifier),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pumpAndSettle();

      expect(find.text('Admin Projects'), findsOneWidget);
    });

    testWidgets('shows loading indicator during login', (tester) async {
      // Use a completer to control when the login resolves
      final completer = Completer<UserCredential>();
      when(() => mockAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(buildTestApp(mockAuth: mockAuth));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField).first,
        'user@test.com',
      );
      await tester.enterText(
        find.byType(TextFormField).last,
        'password123',
      );
      await tester.tap(find.text('Iniciar sesión'));
      await tester.pump(); // Don't settle — we want to see the loading state

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // Complete the future to clean up
      completer.complete(mockCredential);
      await tester.pumpAndSettle();
    });
  });
}
