import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/push_notification_service.dart';
import '../firebase_options.dart';
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
  String? _pendingGoogleIdToken;
  bool googlePhoneRequired = false;
  static bool _googleInitialized = false;

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
        await syncPushToken();
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
      await syncPushToken();
      return true;
    } catch (e) {
      error = e is ApiException
          ? _message(e, 'Téléphone ou mot de passe incorrect.')
          : 'Serveur injoignable. Vérifiez votre connexion.';
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Authentifie le compte Google avec Firebase, puis fait vérifier le jeton
  /// côté Laravel. Un nouveau client devra fournir son téléphone.
  Future<bool> loginWithGoogle() async {
    loading = true;
    error = null;
    googlePhoneRequired = false;
    _pendingGoogleIdToken = null;
    notifyListeners();
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      UserCredential credential;
      if (_isWebPlatform) {
        credential = await FirebaseAuth.instance.signInWithPopup(
          GoogleAuthProvider(),
        );
      } else {
        if (!_googleInitialized) {
          await GoogleSignIn.instance.initialize(
            serverClientId: '1084690560866-bibstirecrffpeosc7r104q7936por91.apps.googleusercontent.com',
          );
          _googleInitialized = true;
        }
        final account = await GoogleSignIn.instance.authenticate();
        final googleAuth = account.authentication;
        final idToken = googleAuth.idToken;
        if (idToken == null || idToken.isEmpty) {
          throw Exception('Google n’a pas fourni de jeton d’identification.');
        }
        credential = await FirebaseAuth.instance.signInWithCredential(
          GoogleAuthProvider.credential(idToken: idToken),
        );
      }

      final firebaseUser = credential.user;
      if (firebaseUser == null) {
        throw Exception('Impossible de récupérer le compte Google.');
      }
      final idToken = await firebaseUser.getIdToken(true);
      if (idToken == null || idToken.isEmpty) {
        throw Exception('Le jeton Google est indisponible.');
      }
      _pendingGoogleIdToken = idToken;
      return await _completeGoogleLogin();
    } catch (e) {
      error = _googleMessage(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Termine une inscription Google en fournissant le téléphone obligatoire.
  Future<bool> completeGoogleSignIn({required String telephone}) async {
    if (_pendingGoogleIdToken == null) {
      error = 'La session Google a expiré. Recommencez.';
      notifyListeners();
      return false;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final ok = await _completeGoogleLogin(phone: telephone.trim());
      return ok;
    } catch (e) {
      error = _message(e, 'Connexion Google impossible.');
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<bool> _completeGoogleLogin({String? phone}) async {
    try {
      final data = await api.request('POST', '/auth/google', body: {
        'id_token': _pendingGoogleIdToken,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      });
      final rawUser = Map<String, dynamic>.from(data['user'] as Map);
      api.token = data['token']?.toString();
      user = UserModel.fromJson(rawUser);
      await StorageService.saveSession(
        token: api.token!,
        userJson: jsonEncode(rawUser),
      );
      await syncPushToken();
      _pendingGoogleIdToken = null;
      googlePhoneRequired = false;
      error = null;
      return true;
    } on ApiException catch (e) {
      final body = e.body is Map ? Map<String, dynamic>.from(e.body as Map) : <String, dynamic>{};
      if (body['code'] == 'PHONE_REQUIRED') {
        googlePhoneRequired = true;
        error = body['message']?.toString() ?? 'Veuillez saisir votre numéro de téléphone.';
        return false;
      }
      rethrow;
    }
  }

  String _googleMessage(Object e) {
    if (e is FirebaseAuthException) {
      if (e.code == 'popup-closed-by-user' || e.code == 'canceled') {
        return 'Connexion Google annulée.';
      }
      return e.message ?? 'Authentification Google impossible.';
    }
    if (e is ApiException) return _message(e, 'Connexion Google impossible.');
    return e.toString().replaceFirst('Exception: ', '');
  }

  bool get _isWebPlatform => kIsWeb;

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
      await syncPushToken();
      return true;
    } catch (e) {
      error = _messageRegister(e);
      return false;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  /// Modifie les informations du client connecté. Renvoie null si tout est bon,
  /// sinon le message d'erreur à afficher.
  Future<String?> updateProfile({
    required String nom,
    required String telephone,
    required String email,
    String? currentPassword,
  }) async {
    try {
      final data = await api.request('PUT', '/auth/profile', authenticated: true, body: {
        'name': nom.trim(),
        'phone': telephone.trim(),
        'email': email.trim().isEmpty ? null : email.trim(),
        if (currentPassword != null && currentPassword.isNotEmpty) 'current_password': currentPassword,
      });
      final rawUser = Map<String, dynamic>.from(data['user'] as Map);
      user = UserModel.fromJson(rawUser);
      await StorageService.saveSession(token: api.token!, userJson: jsonEncode(rawUser));
      notifyListeners();
      return null;
    } catch (e) {
      return _profileMessage(e);
    }
  }

  /// Change le mot de passe. Renvoie null si tout est bon, sinon le message d'erreur.
  Future<String?> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await api.request('PUT', '/auth/password', authenticated: true, body: {
        'current_password': currentPassword,
        'password': newPassword,
      });
      return null;
    } catch (e) {
      return _profileMessage(e);
    }
  }

  String _profileMessage(Object e) {
    if (e is ApiException && e.body is Map) {
      final body = Map<String, dynamic>.from(e.body as Map);
      final errors = body['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
      }
      if (body['message'] != null) return body['message'].toString();
    }
    if (e is ApiException) return 'Modification impossible. Réessayez.';
    return 'Serveur injoignable. Vérifiez votre connexion.';
  }

  /// Enregistre le jeton de cet appareil auprès de l’API Laravel.
  /// Appelée après connexion et restauration de session.
  Future<void> syncPushToken({String? token}) async {
    if (!isAuthenticated) return;
    final fcmToken = token ?? PushNotificationService.instance.currentToken;
    if (fcmToken == null || fcmToken.isEmpty) return;

    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    try {
      await api.request(
        'POST',
        '/fcm-tokens',
        authenticated: true,
        body: {'token': fcmToken, 'platform': platform},
      );
    } catch (e) {
      debugPrint('Enregistrement du jeton FCM impossible : $e');
    }
  }

  Future<void> logout() async {
    try {
      final fcmToken = PushNotificationService.instance.currentToken;
      if (api.token != null && fcmToken != null) {
        await api.request('DELETE', '/fcm-tokens', authenticated: true, body: {'token': fcmToken});
      }
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
