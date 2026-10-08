import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const tokenKey = 'ma_livraison_token';
  static const userKey = 'ma_livraison_user';

  static Future<void> saveSession({
    required String token,
    required String userJson,
  }) async {
    await _storage.write(key: tokenKey, value: token);
    await _storage.write(key: userKey, value: userJson);
  }

  static Future<String?> token() => _storage.read(key: tokenKey);
  static Future<String?> user() => _storage.read(key: userKey);

  static Future<void> clear() => _storage.deleteAll();
}
