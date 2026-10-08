# MA Livraison — Administration

La page Administrateur contient maintenant 6 espaces :
- Tableau de bord
- Commandes
- Livreurs
- Produits
- Publicités
- Carte GPS

## Commandes
Les commandes clients apparaissent dans l'onglet Commandes.
Une commande en `en_attente` peut être attribuée à un livreur disponible.
Le livreur doit ensuite accepter la commande.

## Livreurs
L'administrateur peut :
- créer un livreur ;
- ajouter une photo ;
- renseigner téléphone, e-mail, véhicule et immatriculation ;
- modifier le livreur ;
- suspendre/réactiver son compte ;
- ouvrir la carte de suivi.

## Produits
L'administrateur peut :
- ajouter un produit réel ;
- choisir une catégorie ;
- définir prix et stock ;
- ajouter une image ;
- modifier ;
- activer/désactiver ;
- supprimer.

## Publicités
L'administrateur peut :
- ajouter une publicité ;
- ajouter une image ;
- modifier le titre/description ;
- activer/désactiver ;
- supprimer.

Les publicités actives sont également chargées sur l'accueil public.

## Carte GPS
Choisir un livreur permet d'afficher :
- ses positions enregistrées ;
- son parcours sous forme de ligne ;
- son dernier point sur la carte.

La carte utilise OpenStreetMap via `flutter_map`.

## Test
Après extraction :
```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```
