import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';

/// Dio interceptor that retries failed GET requests with exponential backoff.
///
/// Retries up to [maxRetries] times with delays of 1s, 2s, 4s.
/// Only GET requests are retried to avoid duplicating write operations.
class RetryInterceptor extends Interceptor {
  final Dio _dio;
  final int maxRetries;

  RetryInterceptor(this._dio, {this.maxRetries = 3});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isGet = err.requestOptions.method.toUpperCase() == 'GET';
    final isRetryable = _isRetryableError(err);

    if (!isGet || !isRetryable) {
      return handler.next(err);
    }

    final retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;
    if (retryCount >= maxRetries) {
      return handler.next(err);
    }

    final delay = Duration(seconds: 1 << retryCount); // 1s, 2s, 4s
    await Future<void>.delayed(delay);

    final options = err.requestOptions;
    options.extra['retryCount'] = retryCount + 1;

    try {
      final response = await _dio.fetch<dynamic>(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    }
  }

  bool _isRetryableError(DioException err) {
    // Retry on timeouts and connection errors
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        err.type == DioExceptionType.connectionError) {
      return true;
    }
    // Retry on 5xx server errors
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500) {
      return true;
    }
    // Retry on SocketException (no internet)
    if (err.error is SocketException) {
      return true;
    }
    return false;
  }
}
