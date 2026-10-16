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

  // Préparer l'application sans attendre Firebase.
  final api = ApiClient();
  final auth = AuthProvider(api);

  // Afficher immédiatement l'interface Flutter.
  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaLivraisonApp(),
    ),
  );

  // Restaurer la session indépendamment de Firebase.
  unawaited(auth.restoreSession());

  // Initialiser Firebase en arrière-plan.
  unawaited(_initializeFirebase());
}

Future<void> _initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    debugPrint('Firebase initialisé avec succès.');

    // Les notifications push Web restent activées.
    if (kIsWeb) {
      await PushNotificationService.instance.initialize(
        vapidKey:
            'BJWEExh2-UTg4pmZmZSJ9LuKTU4XbMDsnbPQ5EBO9D_Q6fDmbSE7-EqeAmmf-w9cO6IIQUYSbRITKbqwcTV5sxM',
      );
    }
  } catch (e, stackTrace) {
    debugPrint('Erreur d’initialisation Firebase : $e');
    debugPrintStack(stackTrace: stackTrace);
  }
}
