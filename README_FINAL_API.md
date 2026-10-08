# MA Livraison — Flutter final connecté à l'API

Cette version ne contient plus `MockDriverService`, `MockStoreService` ni les comptes de démonstration dans le code.

## URL API

Par défaut Flutter utilise :

`http://127.0.0.1:8000/api`

Pour Android Emulator :

`flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000/api`

Pour un téléphone réel, remplacez `10.0.2.2` par l'adresse IP LAN du PC, par exemple :

`flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000/api`

Pour Chrome sur le même PC, `127.0.0.1` convient.

## Flux commande

Client → connexion → livreurs disponibles → réservation atomique → création de commande → commande active → suivi.

Livreur → connexion → disponibilité → commandes assignées → accepter → démarrer → récupérer → livrer.

Après `accept`, le backend passe le livreur à `occupe`. Après `deliver`, il repasse à `disponible`.

## Installation

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```
