import 'package:flutter_test/flutter_test.dart';
import 'package:ma_livraison/app.dart';
import 'package:ma_livraison/services/api_client.dart';
import 'package:provider/provider.dart';
import 'package:ma_livraison/providers/auth_provider.dart';

void main() {
  testWidgets('MA Livraison affiche le bouton connexion', (tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AuthProvider(ApiClient()),
        child: const MaLivraisonApp(),
      ),
    );

    expect(find.text('Connexion'), findsOneWidget);
    expect(find.text('Créer un compte'), findsOneWidget);
  });
}
