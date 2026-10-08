# MA Livraison — Front finalisé pour les tests

Cette version du front Flutter contient les écrans de démonstration nécessaires avant le branchement complet de l'API Laravel.

## Comptes de test

### Client
- Téléphone : `97000000`
- Mot de passe : `123456`

Le compte client est disponible directement depuis **Connexion** et ne nécessite pas l'API pour le test.

### Administrateur
- Identifiant : `admin`
- Mot de passe : `admin123`

L'administration permet notamment de :
- voir les commandes ;
- voir le statut des commandes ;
- voir le parcours d'un livreur sur la carte ;
- créer et supprimer des livreurs ;
- gérer les produits ;
- choisir une catégorie lors de l'ajout d'un produit ;
- ajouter/remplacer les photos et modifier les prix ;
- gérer les publicités ;
- consulter les paiements de démonstration.

### Livreur
- Identifiant : `LIV001`
- Mot de passe : `123456`

Deuxième livreur :
- Identifiant : `LIV002`
- Mot de passe : `123456`

## Scénario de test recommandé

1. Démarrer l'application.
2. Cliquer sur **Connexion** puis utiliser le compte client.
3. Aller dans **Se faire livrer**.
4. Choisir un livreur disponible.
5. Renseigner le départ et la destination sur la carte.
6. Valider le paiement de test des frais de livraison : **100 FCFA**.
7. Vérifier que la commande apparaît immédiatement dans **Ma commande** et dans **Mes commandes** du dashboard client.
8. Se déconnecter du client.
9. Ouvrir **Espace livreur** et se connecter avec `LIV001 / 123456`.
10. La commande réservée doit apparaître avec le bouton **Accepter la commande**.
11. Après acceptation : statut `Commande acceptée`, puis possibilité de **Démarrer la course**.
12. Après démarrage : statut `Livraison en cours`.
13. Terminer la course : statut `Livrée` et livreur de nouveau disponible.
14. Se connecter à **Administration** pour vérifier la commande, le livreur et le parcours.

## Navigation de l'accueil

Les boutons **Accueil**, **Services** et **À propos** sont maintenant fonctionnels et font défiler la page vers leur section. Le bouton **Administration** reste accessible depuis l'accueil.

## Paiement

Le front applique actuellement une simulation de paiement. Les frais de livraison sont fixés à **100 FCFA**. Le paiement réel Mobile Money devra être branché côté API Laravel avec confirmation/webhook.

## Données de démonstration

Les produits, publicités, commandes et livreurs du mode front sont en mémoire. Un redémarrage de l'application réinitialise les données de démonstration. C'est volontaire tant que l'API Laravel n'est pas encore branchée.
