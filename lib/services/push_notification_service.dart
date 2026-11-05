import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

/// Gestion centralisée des jetons et des messages FCM.
class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance = PushNotificationService._();
  static const String webVapidKey =
      'BJWEExh2-UTg4pmZmZS9JLuKTU4XbMDsnbPQ5EBO9D_Q6fDmbSE7-EqeAmmf-w9cO6IIQUYSbRITKbqwcTV5sxM';

  String? _currentToken;
  StreamSubscription<String>? _refreshSubscription;

  String? get currentToken => _currentToken;
  Stream<String> get onTokenRefresh => FirebaseMessaging.instance.onTokenRefresh;

  Future<String?> initialize({String? vapidKey}) async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        debugPrint('Notifications refusées par l’utilisateur.');
        return null;
      }

      // Affiche les notifications reçues pendant que l’application est ouverte
      // sur les plateformes Apple. Android gère l’affichage en arrière-plan via FCM.
      await messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      _currentToken = kIsWeb
          ? await messaging.getToken(vapidKey: vapidKey ?? webVapidKey)
          : await messaging.getToken();

      _refreshSubscription ??= messaging.onTokenRefresh.listen((token) {
        _currentToken = token;
      });

      debugPrint('Jeton FCM disponible : ${_currentToken != null}');
      return _currentToken;
    } catch (e, stackTrace) {
      debugPrint('Erreur initialisation notifications : $e');
      debugPrintStack(stackTrace: stackTrace);
      return null;
    }
  }
}

/// Doit rester une fonction de premier niveau pour l’isolate de fond Flutter.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  debugPrint('Notification FCM reçue en arrière-plan : ${message.messageId}');
}
