# MA Livraison — Flutter API final

Cette version utilise Laravel + Sanctum comme source de vérité. Les comptes et commandes de démonstration ont été retirés.

## Lancement local

Chrome :
`flutter pub get && flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api`

Android Emulator :
`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`

Téléphone physique : utiliser l’adresse IP LAN du PC.

Le cycle réel d’une commande est : réservation → livreur_reserve → livreur_accepte → en_cours → colis_recupere → livree.
