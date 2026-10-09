# Paiement MA Livraison

La V5 ajoute un vrai flux de paiement côté commande avec FedaPay : Flutter demande une URL de paiement à Laravel, ouvre cette URL, puis vérifie le statut via Laravel. La clé secrète FedaPay reste côté serveur.

## Flutter

```bash
flutter pub get
flutter analyze
flutter run -d chrome --dart-define=API_BASE_URL=http://127.0.0.1:8000/api
```

## API

Configurer dans `.env` :

```
FEDAPAY_ENV=sandbox
FEDAPAY_SECRET_KEY=VOTRE_CLE_SANDBOX
FEDAPAY_API_BASE_URL=https://sandbox-api.fedapay.com/v1
FEDAPAY_CALLBACK_URL=
```

Pour la production, utiliser la clé live et `https://api.fedapay.com/v1`.

Puis :

```bash
composer install
php artisan migrate
php artisan optimize:clear
php artisan serve --host=0.0.0.0 --port=8000
```

Le serveur ajoute 100 FCFA de frais de service à chaque nouvelle commande et calcule le montant à payer côté serveur.
