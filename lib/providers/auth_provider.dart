import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_client.dart';
import '../services/storage_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiClient api;
  AuthProvider(this.api);

  UserModel? user;
  bool initializing = true;
  bool loading = false;
  String? error;

  bool get isAuthenticated => user != null && api.token != null;
  String? get apiToken => api.token;

  Future<void> restoreSession() async {
    try {
      final token = await StorageService.token();
      final raw = await StorageService.user();
      if (token != null && raw != null) {
        api.token = token;
        user = UserModel.fromJson(jsonDecode(raw));
        final me = await api.request('GET', '/auth/me', authenticated: true);
        user = UserModel.fromJson(Map<String, dynamic>.from(me['user']));
        await StorageService.saveSession(token: token, userJson: jsonEncode(me['user']));
      }
    } catch (_) {
      api.token = null;
      user = null;
      await StorageService.clear();
    } finally {
      initializing = false;
      notifyListeners();
    }
  }

  Future<bool> login({required String telephone, required String password}) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.request('POST', '/auth/login', body: {
        'phone': telephone.trim(),
        'password': password,
      });
      api.token = data['token']?.toString();
      final rawUser = Map<String, dynamic>.from(data['user'] as Map);
      user = UserModel.fromJson(rawUser);
      await StorageService.saveSession(token: api.token!, userJson: jsonEncode(rawUser));
      return true;
    } catch (e) {
      error = _message(e, 'Connexion impossible. Vérifiez vos identifiants.');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> register({
    required String nom,
    required String telephone,
    required String email,
    required String password,
  }) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final data = await api.request('POST', '/auth/register', body: {
        'name': nom.trim(),
        'phone': telephone.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        'password': password,
      });
      api.token = data['token']?.toString();
      final rawUser = Map<String, dynamic>.from(data['user'] as Map);
      user = UserModel.fromJson(rawUser);
      await StorageService.saveSession(token: api.token!, userJson: jsonEncode(rawUser));
      return true;
    } catch (e) {
      error = _messageRegister(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    try {
      if (api.token != null) {
        await api.request('POST', '/auth/logout', authenticated: true);
      }
    } catch (_) {}
    api.token = null;
    user = null;
    await StorageService.clear();
    notifyListeners();
  }

  String _messageRegister(Object e) {
    if (e is ApiException && e.body is Map) {
      final body = Map<String, dynamic>.from(e.body as Map);
      if (e.statusCode == 409 || body['code'] == 'ACCOUNT_EXISTS') {
        return 'Ce compte existe déjà. Utilisez « J’ai déjà un compte » pour vous connecter.';
      }
      if (body['message'] != null) return body['message'].toString();
    }
    return 'Inscription impossible. Vérifiez les informations saisies.';
  }

  String _message(Object e, String fallback) {
    if (e is ApiException && e.body is Map) {
      final body = Map<String, dynamic>.from(e.body as Map);
      if (body['message'] != null) return body['message'].toString();
    }
    return fallback;
  }
}
