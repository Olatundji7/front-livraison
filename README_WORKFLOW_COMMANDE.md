# MA Livraison — nouveau parcours des commandes

## Client
Le client ne voit plus la liste des livreurs disponibles et ne sélectionne plus de livreur.

### Livraison
1. Se faire livrer
2. Adresse de départ
3. Adresse de réception
4. Instruction facultative
5. Envoyer ma demande

### Course personnelle
1. Course personnelle
2. Adresse de récupération
3. Instruction facultative
4. Envoyer ma demande

## Traitement par MA Livraison
La commande est enregistrée dans Laravel/MySQL avec `status=en_attente` et sans livreur attribué.

L'administrateur voit la commande et peut l'attribuer à un livreur disponible.

Un livreur disponible voit seulement qu'une nouvelle commande existe. Après acceptation, les détails nécessaires à la course deviennent disponibles côté livreur.

## Compte existant
L'API renvoie le code `ACCOUNT_EXISTS` avec HTTP 409 lorsqu'un téléphone ou un e-mail est déjà enregistré. Flutter affiche alors :

> Ce compte existe déjà. Utilisez « J’ai déjà un compte » pour vous connecter.
