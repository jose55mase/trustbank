import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrado_server_manager/core/api/auth_interceptor.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client_impl.dart';
import 'package:nitrado_server_manager/core/api/retry_interceptor.dart';
import 'package:nitrado_server_manager/core/storage/auth_provider.dart';

/// Base URL for the Nitrado REST API.
/// On web, routes through a local CORS proxy to avoid browser restrictions.
/// Start the proxy with: `dart run tool/cors_proxy.dart`
const String nitradoBaseUrl = 'https://api.nitrado.net';
const String _corsProxyUrl = 'http://localhost:8089';

/// Resolved base URL — uses the CORS proxy on web, direct URL otherwise.
String get apiBaseUrl => kIsWeb ? _corsProxyUrl : nitradoBaseUrl;

/// Riverpod provider for the configured [Dio] instance.
///
/// Includes auth and retry interceptors, 10-second timeouts.
final dioProvider = Provider<Dio>((ref) {
  final authService = ref.watch(authServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Accept': 'application/json',
      },
    ),
  );

  dio.interceptors.addAll([
    AuthInterceptor(authService),
    RetryInterceptor(dio),
  ]);

  return dio;
});

/// Riverpod provider for [NitradoApiClient].
///
/// Override this provider in tests to inject a mock implementation.
final nitradoApiClientProvider = Provider<NitradoApiClient>((ref) {
  final dio = ref.watch(dioProvider);
  return NitradoApiClientImpl(dio);
});
