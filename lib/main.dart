import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';

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

  final api = ApiClient();
  final auth = AuthProvider(api);

  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaLivraisonApp(),
    ),
  );

  unawaited(auth.restoreSession());

  if (Firebase.apps.isNotEmpty && kIsWeb) {
    unawaited(_initializeWebPush());
  }
}

Future<void> _initializeWebPush() async {
  try {
    await PushNotificationService.instance.initialize(
      vapidKey:
          'BJWEExh2-UTg4pmZmZSJ9LuKTU4XbMDsnbPQ5EBO9D_Q6fDmbSE7-EqeAmmf-w9cO6IIQUYSbRITKbqwcTV5sxM',
    );
  } catch (e, stackTrace) {
    debugPrint('Erreur d’initialisation des notifications Web : $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}
