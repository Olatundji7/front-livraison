# MA Livraison — corrections Front v3

Cette version corrige les trois problèmes signalés :

1. **Commande client absente après retour au dashboard**
   - Le service mémorise maintenant l'ID de la dernière commande réellement créée par le client.
   - Le bouton de suivi ne pointe plus vers une commande mockée en dur (#1).
   - Le statut reste synchronisé avec `MockDriverService`.

2. **Livreur affiché comme occupé avant acceptation**
   - Une réservation client (`reserve_client`) n'est plus considérée comme une course active.
   - Le livreur reste disponible et voit le bouton **Accepter la commande**.
   - Après acceptation seulement : `en_attente -> traitee` et le livreur devient occupé.

3. **Accueil enrichi**
   - Logo officiel MA Livraison.
   - Carrousel local des photos de l'entreprise, avec défilement automatique.
   - Galerie des équipes/activités.
   - Photos individuelles des livreurs dans la sélection des livreurs.
   - Bouton **Administration** visible sur l'accueil.
   - Nouvelle page de connexion administrateur reliée à `AuthProvider` / API Laravel.

## Images intégrées

- `assets/branding/ma_livraison_logo.png`
- `assets/images/team/ma_livraison_team_motos.jpg`
- `assets/images/team/ma_livraison_team_bureau.jpg`
- `assets/images/team/ma_livraison_publicite.jpg`
- `assets/images/drivers/liv001.jpg`
- `assets/images/drivers/liv002.jpg`

## Après remplacement

```bash
flutter clean
flutter pub get
flutter run -d chrome
```

Pour tester le flux livreur :

- LIV001 / 123456
- LIV002 / 123456

Le livreur réservé par le client doit maintenant voir la commande et pouvoir cliquer sur **Accepter la commande**.
