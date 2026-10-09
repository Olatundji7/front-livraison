import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  final int statusCode;
  final dynamic body;

  ApiException(this.statusCode, this.body);

  @override
  String toString() => 'API $statusCode: $body';
}

class ApiClient {
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:8000/api',
  );

  String? token;

  String? mediaUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final value = raw.trim();
    if (value.startsWith('data:')) return value;
    final parsed = Uri.tryParse(value);
    if (parsed != null && parsed.hasScheme) {
      final apiUri = Uri.tryParse(baseUrl);
      if ((parsed.host == '127.0.0.1' || parsed.host == 'localhost') && apiUri != null && apiUri.host.isNotEmpty) {
        return parsed.replace(host: apiUri.host, port: apiUri.hasPort ? apiUri.port : parsed.port).toString();
      }
      return value;
    }
    final normalized = value.startsWith('/') ? value : '/$value';
    return '$baseUrl$normalized';
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