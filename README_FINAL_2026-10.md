# MA Livraison — version intégrée finale

Cette version regroupe les corrections de commande, géolocalisation, tableau de bord livreur/admin, FedaPay et panier.

## Commande
- Le client choisit sa position exacte sur la carte ou utilise sa position GPS.
- Pour une livraison, il choisit aussi la réception exacte.
- Aucun livreur n'est imposé au client.
- Une commande `en_attente` est visible par les livreurs disponibles.
- Un livreur disponible peut l'accepter directement.
- L'administrateur peut toujours attribuer manuellement une commande.

## Distance et tarif
La distance finale est calculée par le backend en additionnant les segments entre les positions GPS enregistrées du livreur pendant la course.

Tarif de course :
- 500 FCFA de base + 300 FCFA/km.
- Au-delà de 3 km : réduction de 20 %.
- Le prix net de course est envoyé dans `delivery_fee`.
- Les 100 FCFA de service MA Livraison sont séparés.

## Paiement FedaPay
Le paiement est proposé lorsque le livreur marque la commande `livree`.

Le montant total du client comprend la course nette + le frais de service de 100 FCFA (+ les produits du panier, le cas échéant).

Les frais réellement facturés par FedaPay sont enregistrés séparément et comptablement imputés sur l'enveloppe de 100 FCFA :

```text
Revenu net MA Livraison = max(0, 100 - frais FedaPay)
```

La liste des commandes de l'administration affiche seulement le prix net de course, pas le détail des 100 FCFA et du frais FedaPay.

## Panier
Le panier est désormais connecté à Laravel/MySQL. Le checkout serveur :
- vérifie le stock ;
- recalcule les prix ;
- calcule la course ;
- ajoute le frais de service ;
- crée les `order_items` ;
- vide le panier après succès.

## Publicités et photos
Les URL d'images sont normalisées par Flutter afin d'éviter les problèmes `localhost`/`127.0.0.1` sur appareil Android. L'API doit avoir son lien de stockage public :

```bash
php artisan storage:link
```

## Lancement Flutter
Exemple Web/Chrome :

```bash
flutter pub get
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

Exemple émulateur Android :

```bash
flutter run -d <emulator> --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

## À faire côté API avant le premier test
Dans le projet Laravel :

```bash
cp .env.example .env
php artisan key:generate
# Vérifier DB_DATABASE=ma_livraison_db, DB_USERNAME=root, DB_PASSWORD=
php artisan migrate
php artisan storage:link
php artisan serve --host=127.0.0.1 --port=8000
```

Pour FedaPay, renseigner uniquement la clé secrète dans `.env` côté Laravel. Ne jamais l'intégrer dans Flutter.
