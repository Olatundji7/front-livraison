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

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialisation des notifications push.
  // La clé VAPID sera fournie à initialize().
  if (kIsWeb) {
  await PushNotificationService.instance.initialize(
    vapidKey: 'BJWEExh2-UTg4pmZmZSJ9LuKTU4XbMDsnbPQ5EBO9D_Q6fDmbSE7-EqeAmmf-w9cO6IIQUYSbRITKbqwcTV5sxM',
  );
}

  final api = ApiClient();
  final auth = AuthProvider(api);

  runApp(
    ChangeNotifierProvider<AuthProvider>.value(
      value: auth,
      child: const MaLivraisonApp(),
    ),
  );

  await auth.restoreSession();
}
