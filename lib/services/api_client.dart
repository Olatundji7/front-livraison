import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'API $statusCode: $body';
}

class ApiClient {
  /// Adresse de l'API (serveur en ligne par défaut).
  ///
  /// Pour tester avec un serveur local, lancer par exemple :
  ///   flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
  /// (émulateur Android : http://10.0.2.2:8000/api)
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://ma.ma3hsarl.com/api',
  );

  String? token;

  /// Transforme une valeur renvoyée par l'API (chemin relatif ou URL absolue)
  /// en URL utilisable par le téléphone.
  ///
  /// Les fichiers Laravel sont servis sous /storage, à la racine du site.
  /// Si l'API renvoie une URL absolue construite avec un mauvais hôte, port ou
  /// schéma (ex. http://127.0.0.1:8000/storage/... à cause d'APP_URL), on la
  /// reconstruit avec l'origine réellement utilisée par l'application.
  String? mediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('data:')) return value;

    final apiUri = Uri.tryParse(baseUrl);
    if (apiUri == null || apiUri.host.isEmpty) return null;
    final origin = Uri(
      scheme: apiUri.scheme,
      host: apiUri.host,
      port: apiUri.hasPort ? apiUri.port : null,
    );

    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final isLocalHost = parsed.host == '127.0.0.1' ||
          parsed.host == 'localhost' ||
          parsed.host == '10.0.2.2';
      final isMedia = parsed.path.startsWith('/storage/') || parsed.path.startsWith('/api/media/');
      if (isLocalHost || isMedia) {
        return origin.replace(path: parsed.path, query: parsed.hasQuery ? parsed.query : null).toString();
      }
      return value;
    }

    var path = value.startsWith('/') ? value : '/$value';
    // Chemin brut du disque public (« drivers/xxx.jpg ») : servi par l'API.
    if (!path.startsWith('/storage/') && !path.startsWith('/api/media/')) {
      path = '/api/media$path';
    }
    return origin.replace(path: path).toString();
  }

  Future<dynamic> request(
    String method,
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
    bool authenticated = false,
  }) async {
    final uri = Uri.parse('$baseUrl$path').replace(
      queryParameters: query == null || query.isEmpty ? null : query,
    );

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    if (authenticated && token != null && token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer ${token!}';
    }

    final payload = body == null ? null : jsonEncode(body);
    late http.Response response;
    const timeout = Duration(seconds: 20);

    switch (method.toUpperCase()) {
      case 'GET':
        response = await http.get(uri, headers: headers).timeout(timeout);
        break;
      case 'POST':
        response = await http
            .post(uri, headers: headers, body: payload)
            .timeout(timeout);
        break;
      case 'PUT':
        response = await http
            .put(uri, headers: headers, body: payload)
            .timeout(timeout);
        break;
      case 'PATCH':
        response = await http
            .patch(uri, headers: headers, body: payload)
            .timeout(timeout);
        break;
      case 'DELETE':
        response = await http
            .delete(uri, headers: headers, body: payload)
            .timeout(timeout);
        break;
      default:
        throw UnsupportedError('Méthode HTTP non supportée: $method');
    }

    return _decodeResponse(response);
  }

  /// Envoie une requête multipart/form-data.
  ///
  /// Utilisé notamment pour les produits avec upload d'image côté Admin.
  Future<dynamic> multipart(
    String method,
    String path, {
    Map<String, String>? fields,
    Uint8List? fileBytes,
    String? fileName,
    String fileField = 'image',
    bool authenticated = true,
  }) async {
    final uri = Uri.parse('$baseUrl$path');
    final request = http.MultipartRequest(method.toUpperCase(), uri);

    request.headers['Accept'] = 'application/json';

    if (authenticated && token != null && token!.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer ${token!}';
    }

    if (fields != null && fields.isNotEmpty) {
      request.fields.addAll(fields);
    }

    if (fileBytes != null) {
      request.files.add(
        http.MultipartFile.fromBytes(
          fileField,
          fileBytes,
          filename: fileName ?? 'upload.jpg',
        ),
      );
    }

    final streamed = await request.send().timeout(const Duration(seconds: 30));
    final response = await http.Response.fromStream(streamed);

    return _decodeResponse(response);
  }

  dynamic _decodeResponse(http.Response response) {
    dynamic decoded;

    try {
      decoded = response.body.isEmpty
          ? <String, dynamic>{}
          : jsonDecode(response.body);
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(response.statusCode, decoded);
    }

    return decoded;
  }
}