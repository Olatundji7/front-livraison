# Brief de revue V4 — Flutter MA Livraison

## Base conservée
- Authentification réelle avec Laravel Sanctum.
- Accueil MA Livraison, logo, équipe, produits et publicités.
- Espace Client, Livreur et Admin.
- Gestion Admin des commandes, livreurs, produits et publicités.
- Carte Admin existante et suivi GPS.
- Aucun ancien MockDriverService / MockStoreService utilisé dans le flux métier.

## Commandes
- Le client ne choisit plus un livreur.
- Le client dépose sa demande auprès de MA Livraison.
- Les livreurs disponibles voient les nouvelles demandes et peuvent les accepter directement.
- L’Admin surveille les commandes et peut aussi faire une attribution manuelle.

## Localisation
- Le client peut choisir la récupération/départ sur une carte.
- Un bouton permet d’utiliser la position GPS exacte du téléphone, dans un fonctionnement comparable au partage de position d’une messagerie.
- Pour une livraison : départ + réception.
- Pour une course personnelle : récupération uniquement.

## Suivi
- Le client voit la position du livreur pendant la course.
- Le livreur dispose d’un écran « Mes courses » et d’une carte de la commande active.
- L’Admin voit les positions des livreurs et l’itinéraire historique sélectionné.
- La distance affichée après déplacement correspond au compteur GPS cumulé côté serveur.

## Publicités
- Les images restent gérées depuis Admin.
- Les URLs d’image sont normalisées côté Flutter et passent par l’endpoint `/api/media/*` côté Laravel afin d’éviter les erreurs d’affichage observées sur Chrome/Web.
