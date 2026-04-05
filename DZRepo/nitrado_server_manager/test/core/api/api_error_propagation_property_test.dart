// Feature: nitrado-server-manager, Property 4: Propagación de errores de API en control del servidor
// **Validates: Requirements 3.4**

import 'package:dio/dio.dart';
import 'package:glados/glados.dart';
import 'package:nitrado_server_manager/core/api/api_exceptions.dart';
import 'package:nitrado_server_manager/core/api/nitrado_api_client_impl.dart';

/// Generator for non-empty error message strings using printable ASCII chars.
/// Avoids control characters to keep messages realistic.
final _nonEmptyErrorMessage = any.nonEmptyStringOf(
  'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 .,!?:-_()/',
);

void main() {
  Glados(_nonEmptyErrorMessage, ExploreConfig(numRuns: 100)).test(
    'API error message is propagated in ApiException for 4xx responses',
    (String errorMessage) async {
      final dio = Dio(BaseOptions(baseUrl: 'https://api.nitrado.net'));
      final client = NitradoApiClientImpl(dio);

      // Intercept all requests and reject with a 422 containing the message
      dio.interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(DioException(
          requestOptions: options,
          response: Response(
            requestOptions: options,
            statusCode: 422,
            data: <String, dynamic>{'message': errorMessage},
          ),
          type: DioExceptionType.badResponse,
        )),
      ));

      try {
        await client.request(() => dio.get<dynamic>('/test'));
        fail('Expected ApiException to be thrown');
      } on ApiException catch (e) {
        expect(e.message, contains(errorMessage));
      }
    },
  );
}
