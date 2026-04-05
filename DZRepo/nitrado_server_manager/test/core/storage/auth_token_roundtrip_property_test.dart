// Feature: nitrado-server-manager, Property 1: Round trip de almacenamiento de token
// **Validates: Requirements 1.1, 1.4**

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart' hide expect;
import 'package:glados/glados.dart';
import 'package:mocktail/mocktail.dart' show Fake;

import 'package:nitrado_server_manager/core/storage/auth_service_impl.dart';

/// In-memory fake of [FlutterSecureStorage] backed by a simple [Map].
///
/// Extends [Fake] so unimplemented members throw clear errors instead of
/// requiring boilerplate stubs for every property/method on the class.
class _FakeSecureStorage extends Fake implements FlutterSecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> write({
    required String key,
    required String? value,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    if (value != null) {
      _store[key] = value;
    } else {
      _store.remove(key);
    }
  }

  @override
  Future<String?> read({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return _store[key];
  }

  @override
  Future<void> delete({
    required String key,
    IOSOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    MacOsOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    _store.remove(key);
  }
}

/// Generator for non-empty token strings (printable ASCII, 1-200 chars).
final _nonEmptyTokenGen = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789'
  '_-=+!@#\$%^&*()[]{}|;:,.<>?/~`',
);

void main() {
  Glados(_nonEmptyTokenGen, ExploreConfig(numRuns: 100)).test(
    'saveToken then getToken returns the same token, '
    'deleteToken then getToken returns null',
    (String token) async {
      final fakeStorage = _FakeSecureStorage();
      final authService = AuthServiceImpl(storage: fakeStorage);

      // Round-trip: save → get must return the same token
      await authService.saveToken(token);
      final retrieved = await authService.getToken();
      expect(retrieved, equals(token));

      // After delete, get must return null
      await authService.deleteToken();
      final afterDelete = await authService.getToken();
      expect(afterDelete, isNull);
    },
  );
}
