import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrado_server_manager/core/api/backend_api_client.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';

/// Base URL for the Spring Boot backend.
///
/// All Nitrado API calls are now proxied through the backend, which handles
/// authentication, error translation, and logging. The Flutter app no longer
/// communicates directly with the Nitrado API.
///
/// For Android emulator, use 10.0.2.2 instead of localhost.
/// For iOS simulator, localhost works fine.
/// For web, localhost works fine.
/// For physical devices, use the machine's local IP address.
const String _backendBaseUrl = 'http://localhost:8080';

/// Android emulator needs a special IP to reach the host machine.
const String _androidEmulatorBaseUrl = 'http://10.0.2.2:8080';

/// Resolved backend URL based on platform.
String get backendBaseUrl {
  if (kIsWeb) return _backendBaseUrl;
  // For native platforms, default to localhost.
  // Override with _androidEmulatorBaseUrl if testing on Android emulator.
  return _backendBaseUrl;
}

/// Riverpod provider for the configured [Dio] instance.
///
/// Points to the Spring Boot backend. No auth interceptor needed since
/// the backend handles Nitrado authentication internally.
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: backendBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  return dio;
});

/// Riverpod provider for [NitradoApiClient].
///
/// Uses [BackendApiClient] which routes all requests through the Spring Boot
/// backend instead of calling the Nitrado API directly.
///
/// Override this provider in tests to inject a mock implementation.
final nitradoApiClientProvider = Provider<NitradoApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return BackendApiClient(dio);
});
