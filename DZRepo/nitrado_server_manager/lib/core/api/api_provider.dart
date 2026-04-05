import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nitrado_server_manager/core/api/auth_interceptor.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client_impl.dart';
import 'package:nitrado_server_manager/core/api/retry_interceptor.dart';
import 'package:nitrado_server_manager/core/storage/auth_provider.dart';

/// Base URL for the Nitrado REST API.
const String nitradoBaseUrl = 'https://api.nitrado.net';

/// Riverpod provider for the configured [Dio] instance.
///
/// Includes auth and retry interceptors, 10-second timeouts.
final dioProvider = Provider<Dio>((ref) {
  final authService = ref.watch(authServiceProvider);

  final dio = Dio(
    BaseOptions(
      baseUrl: nitradoBaseUrl,
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
