# MA Livraison — Front v4 finalisé

Cette version consolide le front Flutter autour de trois espaces : Client, Livreur et Administration.

## 1. Test administrateur local

Depuis l'accueil : **Administration**.

Identifiant : `admin`
Mot de passe : `admin123`

Le mode admin local permet de tester le front avant le raccordement complet à Laravel.

## 2. Administration

- Tableau de bord et statistiques de démonstration
- Gestion des commandes
- Gestion des livreurs
- Création/suppression de livreurs
- Visualisation du parcours d'un livreur sur carte
- Gestion des produits
- Catégories
- Ajout de photo produit depuis la galerie
- Modification du nom, prix, stock, catégorie et description
- Suppression d'un produit
- Gestion des publicités/blog
- Activation/désactivation d'une publicité
- Ajout d'une image publicitaire depuis la galerie
- Consultation des paiements de test

## 3. Client

- Création de livraison
- Sélection d'un livreur disponible
- Paiement simulé de 100 FCFA de frais de livraison lors de la validation
- Dashboard avec la dernière commande
- Suivi de statut : `en_attente -> traitee -> en_cours -> livree`
- Catalogue produits
- Recherche et catégories
- Détails d'un produit
- Panier
- Paiement de test avec ajout automatique de 100 FCFA de frais de livraison

## 4. Livreur

Le `MockDriverService` respecte désormais le flux :

`commande créée -> commande en attente -> livreur accepte -> traitee -> démarre -> en_cours -> termine -> livree`

Une réservation client ne rend plus le livreur occupé. Le livreur devient occupé uniquement après l'acceptation.

Le bouton **Accepter la commande** reste disponible pour un livreur réservé mais pas encore engagé.

## 5. Accueil / publicité

Les images de l'entreprise sont locales afin de limiter la dépendance au réseau. Le hero fait défiler les publicités en boucle avec un changement toutes les 5 secondes.

Les images ne sont pas téléchargées à chaque défilement depuis Internet : elles sont incluses dans l'application et mises en cache par Flutter.

## 6. Logo et images

Le logo officiel cheval de MA Livraison est utilisé dans l'application. Les images d'équipe sont distinctes des photos utilisées pour les livreurs.

## 7. API Laravel

Le front conserve `ApiClient` et peut être progressivement raccordé aux endpoints du cahier des charges. Les règles métier sensibles (prix, paiement, réservation, concurrence et autorisations) devront rester imposées par Laravel.

## 8. Android

La permission Internet est maintenant déclarée dans le manifeste principal et la permission de localisation est présente.

Commandes de test recommandées :

```bash
flutter clean
flutter pub get
flutter analyze
flutter run -d chrome
flutter run -d <votre-emulateur>
```

## 9. iOS

Le ZIP source utilisé pour cette version ne contenait pas de dossier `ios/`. Le code Dart et les dépendances sont prévus pour être portables Android/iOS, mais la génération/signature iOS doit être effectuée sur macOS avec Flutter/Xcode :

```bash
flutter create --platforms=ios .
flutter pub get
flutter build ios
```

Dans `ios/Runner/Info.plist`, prévoir les descriptions d'utilisation de la localisation et de la photothèque lorsque les fonctionnalités GPS/photo sont activées.

## 10. Paiements

Les paiements présents dans le front sont volontairement marqués comme **simulés**. Ils ne constituent pas une intégration Mobile Money réelle. La vraie transaction doit être branchée sur le backend Laravel et son webhook.
