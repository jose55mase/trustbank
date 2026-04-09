/// Proxy CORS simple para desarrollo de Flutter web.
///
/// Ejecutar con: `dart run tool/cors_proxy.dart`
///
/// Reenvía todas las peticiones de http://localhost:8089/*
/// a https://api.nitrado.net/* agregando los headers CORS necesarios.
library;

import 'dart:io';
import 'dart:convert';

const _proxyPort = 8089;
const _targetHost = 'api.nitrado.net';

void main() async {
  final server = await HttpServer.bind('localhost', _proxyPort);
  print('CORS proxy escuchando en http://localhost:$_proxyPort');
  print('Reenviando a https://$_targetHost');

  await for (final request in server) {
    _handleRequest(request);
  }
}

Future<void> _handleRequest(HttpRequest request) async {
  final response = request.response;

  // Agregar headers CORS a todas las respuestas.
  response.headers.set('Access-Control-Allow-Origin', '*');
  response.headers.set('Access-Control-Allow-Methods',
      'GET, POST, PUT, DELETE, PATCH, OPTIONS');
  response.headers.set('Access-Control-Allow-Headers',
      'Origin, Content-Type, Accept, Authorization');
  response.headers.set('Access-Control-Max-Age', '86400');

  // Responder preflight OPTIONS directamente.
  if (request.method == 'OPTIONS') {
    response.statusCode = 200;
    await response.close();
    return;
  }

  try {
    // Leer el body de la petición entrante.
    final requestBody = await utf8.decodeStream(request);

    // Crear la petición hacia Nitrado.
    final client = HttpClient();
    final targetUri = Uri.https(_targetHost, request.uri.path, request.uri.queryParameters.isNotEmpty ? request.uri.queryParameters : null);

    final proxyRequest = await client.openUrl(request.method, targetUri);

    // Copiar headers relevantes (especialmente Authorization).
    String? authHeader;
    request.headers.forEach((name, values) {
      if (name.toLowerCase() == 'host') return;
      if (name.toLowerCase() == 'connection') return;
      for (final v in values) {
        proxyRequest.headers.add(name, v);
        if (name.toLowerCase() == 'authorization') {
          authHeader = '${v.substring(0, 15)}...';
        }
      }
    });
    proxyRequest.headers.set('Host', _targetHost);
    print('  → Auth: ${authHeader ?? "NO AUTHORIZATION HEADER"}');

    // Enviar body si existe.
    if (requestBody.isNotEmpty) {
      proxyRequest.write(requestBody);
    }

    final proxyResponse = await proxyRequest.close();

    // Copiar status y headers de la respuesta de Nitrado.
    response.statusCode = proxyResponse.statusCode;
    proxyResponse.headers.forEach((name, values) {
      if (name.toLowerCase() == 'transfer-encoding') return;
      for (final v in values) {
        response.headers.add(name, v);
      }
    });

    // Re-aplicar CORS (por si Nitrado los sobreescribió).
    response.headers.set('Access-Control-Allow-Origin', '*');

    // Copiar el body de la respuesta.
    final responseBody = await proxyResponse.transform(utf8.decoder).join();
    response.write(responseBody);
    await response.close();

    // Log para debug — muestra los primeros 500 chars de la respuesta.
    if (request.uri.path == '/services') {
      final preview = responseBody.length > 500
          ? '${responseBody.substring(0, 500)}...'
          : responseBody;
      print('  ← Respuesta: $preview');
    }

    client.close(force: false);

    print('${request.method} ${request.uri.path} → ${proxyResponse.statusCode}');
  } catch (e) {
    print('Error en proxy: $e');
    response.statusCode = 502;
    response.write('Proxy error: $e');
    await response.close();
  }
}
