# MA Livraison — Flutter Frontend

Frontend Flutter responsive pour MA3H Sarl, ciblant Android, iOS, Web et Desktop.

## Backend
Base URL prévue par le contrat API :
`https://api.ma-livraison.com/api/v1`

Le frontend suit les routes et formats du document Contrat d'API V1 du 15 septembre 2026 :
- `/auth/register`
- `/auth/login`
- `/auth/logout`
- `/services`
- `/orders`
- `/orders/{id}`
- `/deliverers/nearby`
- `/deliverer/availability`
- `/deliverer/orders/available`
- `/deliverer/orders/{id}/accept`
- `/deliverer/orders/{id}/status`
- `/deliverer/location`
- `/deliverer/orders/{id}/invoice`
- `/admin/deliverers/pending`
- `/admin/deliverers/{id}/validate`
- `/admin/orders`
- `/admin/orders/{id}/assign`
- `/admin/admins`

## Lancer
```bash
flutter pub get
flutter run
```

Pour le web :
```bash
flutter run -d chrome
```

Pour Android :
```bash
flutter run -d android
```

## Couleurs
Le site MA3H présente une identité bleue. Le frontend utilise comme couleur principale `#0B4F9C`, avec un bleu foncé `#083B73` et un fond clair.

## Photos
L'accueil utilise des visuels distants afin de pouvoir démarrer sans logo local. Remplacez-les plus tard par les photos officielles de MA Livraison dans `lib/core/app_assets.dart`.

## Carte
Le contrat prévoit Google Maps pour le backend/projet. Ici, la couche frontend utilise `flutter_map`, afin d'avoir une interface cartographique compatible mobile et desktop sans dépendance native Google Maps.

## Temps réel
`RealtimeService` est préparé pour Laravel Reverb/WebSocket. Le canal privé doit être raccordé à la configuration Reverb du backend, notamment l'authentification des channels privés.

## Important
Le code respecte le contrat API fourni. Les endpoints non encore testés côté Laravel ne doivent pas être considérés comme prêts en production.
