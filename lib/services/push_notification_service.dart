import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();

  static final PushNotificationService instance =
      PushNotificationService._();

  Future<String?> initialize({String? vapidKey}) async {
    try {
      final messaging = FirebaseMessaging.instance;

      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus ==
          AuthorizationStatus.denied) {
        debugPrint('Notifications refusées par l’utilisateur.');
        return null;
      }

      final token = kIsWeb
          ? await messaging.getToken(
              vapidKey: vapidKey,
            )
          : await messaging.getToken();

      debugPrint('Jeton FCM disponible : ${token != null}');
      return token;
    } catch (e) {
      debugPrint('Erreur initialisation notifications : $e');
      return null;
    }
  }
}
