import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'providers/auth_provider.dart';
import 'services/api_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final api = ApiClient();
  final auth = AuthProvider(api);
  runApp(ChangeNotifierProvider<AuthProvider>.value(value: auth, child: const MaLivraisonApp()));
  await auth.restoreSession();
}
