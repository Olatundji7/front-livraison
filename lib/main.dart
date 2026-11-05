import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'app.dart';
import 'firebase_options.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase doit être prêt avant qu'un utilisateur puisse lancer Google Sign-In.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialisé avec succès.');
  } catch (e, stackTrace) {
    debugPrint('Erreur d’initialisation Firebase : $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  if (Firebase.apps.isNotEmpty) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  final api = ApiClient();
  final auth = AuthProvider(api);

  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaLivraisonApp(),
    ),
  );

  unawaited(_restoreAndInitializePush(auth));
}

Future<void> _restoreAndInitializePush(AuthProvider auth) async {
  await auth.restoreSession();
  if (Firebase.apps.isEmpty) return;

  final token = await PushNotificationService.instance.initialize();
  if (token != null && auth.isAuthenticated) {
    await auth.syncPushToken(token: token);
  }

  PushNotificationService.instance.onTokenRefresh.listen((newToken) {
    auth.syncPushToken(token: newToken);
  });

  FirebaseMessaging.onMessage.listen((message) {
    final title = message.notification?.title ?? 'MA Livraison';
    final body = message.notification?.body ?? 'Vous avez une nouvelle notification.';
    maLivraisonMessengerKey.currentState?.showSnackBar(
      SnackBar(content: Text('$title — $body'), behavior: SnackBarBehavior.floating),
    );
  });
}
