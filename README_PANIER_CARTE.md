# Panier, carte et paiement

- Le panier est stocké côté Laravel (`carts` / `cart_items`).
- Les prix des produits sont recalculés côté serveur au checkout.
- La commande panier utilise la même logique de distance que les livraisons classiques.
- La carte permet de placer le départ et la réception, ou d’utiliser la position GPS du téléphone.
- Le paiement FedaPay apparaît seulement après le passage de la commande à `livree`.
- Les 100 FCFA de service restent séparés du prix net de la course.


## Parcours final
1. Le client peut choisir la position exacte sur la carte ou utiliser sa position GPS.
2. Une livraison est créée en `en_attente`; aucun livreur n'est imposé par le client.
3. Un livreur disponible voit la commande et peut l'accepter directement. L'administration peut aussi l'attribuer manuellement.
4. Le livreur partage périodiquement sa position. La distance finale est calculée en additionnant les segments GPS réels.
5. Après `livree`, le client peut lancer le paiement FedaPay.
6. Le panier est persistant côté serveur et son checkout recalculera les prix et le stock côté API.
7. Le prix de course présenté à l'administration est le prix net après réduction; les 100 FCFA de service sont gérés séparément et servent d'enveloppe pour les frais FedaPay.
