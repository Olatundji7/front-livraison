import 'dart:math';

import 'package:flutter/foundation.dart';

/// ===============================================================
/// MODE TEST - SERVICE LIVREUR / CLIENT
/// ===============================================================
///
/// Simule le backend Laravel pendant le développement Flutter.
///
/// FLUX COMMANDE :
///
/// Client choisit un livreur
///        ↓
/// Livréur réservé
///        ↓
/// Commande = en_attente
///        ↓
/// Livréur voit la commande
///        ↓
/// Livréur clique "Accepter"
///        ↓
/// Commande = traitee
/// Livréur = occupé
///        ↓
/// "Démarrer la course"
///        ↓
/// Commande = en_cours
///        ↓
/// "Terminer"
///        ↓
/// Commande = livree
/// Livréur = disponible
///
/// ===============================================================

class MockDriverService extends ChangeNotifier {
  // =============================================================
  // SINGLETON
  // =============================================================

  static final MockDriverService instance = MockDriverService._();

  MockDriverService._();

  /// Tarif de base appliqué selon la distance.
  /// Les kilomètres supplémentaires après 3 km sont facturés par tranche commencée de 1 km.
  static int calculerTarifBase(double distanceKm) {
    if (distanceKm <= 0) return 600;
    if (distanceKm <= 1.5) return 600;
    if (distanceKm <= 2.0) return 700;
    if (distanceKm <= 3.0) return 1000;

    final tranchesSupplementaires = (distanceKm - 3.0).ceil();
    return 1000 + (tranchesSupplementaires * 300);
  }

  /// Réduction client de 20 % à partir de 4 km inclus.
  /// Entre plus de 3 km et moins de 4 km, le tarif reste normal.
  static int calculerTarifClient(double distanceKm) {
    final tarifBase = calculerTarifBase(distanceKm);
    if (distanceKm < 4.0) return tarifBase;
    return (tarifBase * 0.80).round();
  }

  // =============================================================
  // LIVREURS TEST
  // =============================================================

  final List<Map<String, dynamic>> _drivers = [
    {
      'id': 1,
      'identifiant': 'LIV001',
      'mot_de_passe': '123456',
      'nom': 'Karim Boukari',
      'telephone': '+22997889900',

      // Disponible au lancement.
      'disponible': true,

      // Réservé par un client ?
      'reserve_client': false,
      'reservation_type': null,

      'latitude': 6.3703,
      'longitude': 2.3912,
    },
    {
      'id': 2,
      'identifiant': 'LIV002',
      'mot_de_passe': '123456',
      'nom': 'Rachidi Ouedraogo',
      'telephone': '+22997001122',

      'disponible': true,
      'reserve_client': false,
      'reservation_type': null,

      'latitude': 6.3720,
      'longitude': 2.3950,
    },
  ];

  // =============================================================
  // COMMANDES
  // =============================================================

  final List<Map<String, dynamic>> _orders = [
    {
      'id': 1001,
      'client': 'Fatouma Alassane',
      'telephone_client': '+22997001122',
      'type': 'livraison',

      'pickup_adresse': 'Marché Arzèkè',
      'dest_adresse': 'Quartier Zongo',

      'pickup_lat': 6.3700,
      'pickup_lng': 2.3900,

      'dest_lat': 6.3750,
      'dest_lng': 2.4000,

      'distance_km': 3.2,
      'prix_estime': 1300,

      'statut': 'en_attente',

      'deliverer_id': null,
      'requested_driver_id': null,

      'note': 'Sonner à l’arrivée',
    },
    {
      'id': 1002,
      'client': 'Jean Houngbédji',
      'telephone_client': '+22996112233',
      'type': 'course',

      'pickup_adresse': 'Place de l’Étoile Rouge',
      'dest_adresse': 'Cadjèhoun',

      'pickup_lat': 6.3650,
      'pickup_lng': 2.3850,

      'dest_lat': 6.3600,
      'dest_lng': 2.4100,

      'distance_km': 4.5,
      'prix_estime': 1280,

      'statut': 'en_attente',

      'deliverer_id': null,
      'requested_driver_id': null,

      'note': '',
    },
  ];

  // =============================================================
  // COURSES TERMINÉES
  // =============================================================

  final List<Map<String, dynamic>> _completedOrders = [];

  // =============================================================
  // LIVREUR CONNECTÉ
  // =============================================================

  Map<String, dynamic>? _currentDriver;

  // Dernière commande réellement créée depuis l'espace client.
  // Cela évite de retomber sur les commandes de démonstration 1001/1002.
  int? _latestClientOrderId;

  Map<String, dynamic>? get currentDriver {
    if (_currentDriver == null) return null;

    return Map<String, dynamic>.from(_currentDriver!);
  }

  // =============================================================
  // LISTE DES LIVREURS
  // =============================================================

  List<Map<String, dynamic>> get drivers {
    return _drivers
        .map((driver) => Map<String, dynamic>.from(driver))
        .toList();
  }

  // =============================================================
  // LIVREURS DISPONIBLES POUR LE CLIENT
  // =============================================================

  List<Map<String, dynamic>> get availableDriversForClient {
    return _drivers
        .where(
          (driver) =>
              driver['disponible'] == true &&
              driver['reserve_client'] != true,
        )
        .map((driver) => Map<String, dynamic>.from(driver))
        .toList();
  }

  // =============================================================
  // RECHERCHER UN LIVREUR
  // =============================================================

  Map<String, dynamic>? getDriverById(int driverId) {
    try {
      final driver = _drivers.firstWhere(
        (driver) => driver['id'] == driverId,
      );

      return Map<String, dynamic>.from(driver);
    } catch (_) {
      return null;
    }
  }

  // =============================================================
  // CONNEXION LIVREUR
  // =============================================================

  Map<String, dynamic>? login(
    String identifiant,
    String motDePasse,
  ) {
    try {
      final driver = _drivers.firstWhere(
        (driver) =>
            driver['identifiant'] == identifiant &&
            driver['mot_de_passe'] == motDePasse,
      );

      _currentDriver = Map<String, dynamic>.from(driver);

      notifyListeners();

      return Map<String, dynamic>.from(_currentDriver!);
    } catch (_) {
      return null;
    }
  }

  // =============================================================
  // DÉCONNEXION
  // =============================================================

  void logout() {
    if (_currentDriver != null) {
      final driverId = _currentDriver!['id'];

      final driver = getDriverById(driverId);

      // Ne pas modifier un livreur réservé/engagé.
      if (driver != null &&
          driver['reserve_client'] != true &&
          activeOrder == null) {
        setAvailability(false);
      }
    }

    _currentDriver = null;

    notifyListeners();
  }

  // =============================================================
  // DISPONIBILITÉ
  // =============================================================

  bool get isAvailable {
    return _currentDriver?['disponible'] == true;
  }

  bool get isReserved {
    return _currentDriver?['reserve_client'] == true;
  }

  void setAvailability(bool value) {
    if (_currentDriver == null) return;

    // Impossible de devenir disponible manuellement
    // lorsqu'une commande est active.
    if (value && activeOrder != null) {
      return;
    }

    // Une réservation client empêche de modifier
    // librement la disponibilité.
    if (value && _currentDriver!['reserve_client'] == true) {
      return;
    }

    _currentDriver!['disponible'] = value;

    final driverId = _currentDriver!['id'];

    final index = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (index != -1) {
      _drivers[index]['disponible'] = value;
    }

    notifyListeners();
  }

  // =============================================================
  // RÉSERVER UN LIVREUR POUR UN CLIENT
  // =============================================================

  Map<String, dynamic>? reserveDriverForClient({
    required int driverId,
    required String type,
  }) {
    final index = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (index == -1) {
      return null;
    }

    final driver = _drivers[index];

    // Le livreur doit être libre.
    if (driver['disponible'] != true ||
        driver['reserve_client'] == true) {
      return null;
    }

    // Réservation.
    driver['reserve_client'] = true;
    driver['reservation_type'] = type;

    // IMPORTANT :
    // Le livreur n'est PAS encore occupé.
    //
    // Il doit encore pouvoir recevoir et accepter
    // la commande.
    driver['disponible'] = true;

    if (_currentDriver?['id'] == driverId) {
      _currentDriver = Map<String, dynamic>.from(driver);
    }

    notifyListeners();

    return Map<String, dynamic>.from(driver);
  }

  // =============================================================
  // ANNULER UNE RÉSERVATION
  // =============================================================

  void cancelDriverReservation(int driverId) {
    final index = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (index == -1) return;

    final driver = _drivers[index];

    // Impossible d'annuler une réservation lorsqu'une
    // commande existe déjà.
    final hasOrder = _orders.any(
      (order) =>
          (order['requested_driver_id'] == driverId ||
              order['deliverer_id'] == driverId) &&
          order['statut'] != 'livree',
    );

    if (hasOrder) {
      return;
    }

    driver['reserve_client'] = false;
    driver['reservation_type'] = null;
    driver['disponible'] = true;

    if (_currentDriver?['id'] == driverId) {
      _currentDriver = Map<String, dynamic>.from(driver);
    }

    notifyListeners();
  }

  // =============================================================
  // POSITION DU LIVREUR
  // =============================================================

  void updateLocation(
    double latitude,
    double longitude,
  ) {
    if (_currentDriver == null) return;

    _currentDriver!['latitude'] = latitude;
    _currentDriver!['longitude'] = longitude;

    final driverId = _currentDriver!['id'];

    final index = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (index != -1) {
      _drivers[index]['latitude'] = latitude;
      _drivers[index]['longitude'] = longitude;
    }

    notifyListeners();
  }

  // =============================================================
  // COMMANDES DISPONIBLES
  // =============================================================

  List<Map<String, dynamic>> get availableOrders {
    final currentDriverId = _currentDriver?['id'];

    return _orders
        .where((order) {
          if (order['statut'] != 'en_attente') {
            return false;
          }

          if (order['deliverer_id'] != null) {
            return false;
          }

          final requestedDriverId =
              order['requested_driver_id'];

          // Commande réservée à un livreur précis.
          if (requestedDriverId != null) {
            return currentDriverId != null &&
                requestedDriverId == currentDriverId;
          }

          // Commande générale.
          return true;
        })
        .map(
          (order) => Map<String, dynamic>.from(order),
        )
        .toList();
  }

  // =============================================================
  // COMMANDES EN ATTENTE DU LIVREUR CONNECTÉ
  // =============================================================

  List<Map<String, dynamic>> get pendingOrdersForCurrentDriver {
    final driverId = _currentDriver?['id'];

    if (driverId == null) {
      return [];
    }

    return _orders
        .where(
          (order) =>
              order['statut'] == 'en_attente' &&
              order['deliverer_id'] == null &&
              order['requested_driver_id'] == driverId,
        )
        .map(
          (order) => Map<String, dynamic>.from(order),
        )
        .toList();
  }

  // =============================================================
  // DERNIÈRE COMMANDE
  // =============================================================

  Map<String, dynamic>? get latestClientOrder {
    final id = _latestClientOrderId;
    if (id != null) {
      return getOrderById(id);
    }

    return null;
  }

  // =============================================================
  // TOUTES LES COMMANDES
  // =============================================================

  List<Map<String, dynamic>> get orders {
    return _orders
        .map(
          (order) => Map<String, dynamic>.from(order),
        )
        .toList();
  }

  // =============================================================
  // COMMANDE ACTIVE DU LIVREUR
  // =============================================================

  Map<String, dynamic>? get activeOrder {
    if (_currentDriver == null) {
      return null;
    }

    final driverId = _currentDriver!['id'];

    try {
      return _orders
          .where(
            (order) =>
                _toInt(order['deliverer_id']) == _toInt(driverId) &&
                (order['statut'] == 'traitee' ||
                    order['statut'] == 'en_cours'),
          )
          .map(
            (order) => Map<String, dynamic>.from(order),
          )
          .first;
    } catch (_) {
      return null;
    }
  }

  // =============================================================
  // DISTANCE JUSQU'AU DÉPART
  // =============================================================

  double distanceToPickup(
    Map<String, dynamic> order,
  ) {
    if (_currentDriver == null) {
      return 999;
    }

    final lat1 =
        (_currentDriver!['latitude'] as num).toDouble();

    final lng1 =
        (_currentDriver!['longitude'] as num).toDouble();

    final lat2 =
        (order['pickup_lat'] as num).toDouble();

    final lng2 =
        (order['pickup_lng'] as num).toDouble();

    return _calculateDistance(
      lat1,
      lng1,
      lat2,
      lng2,
    );
  }

  // =============================================================
  // ACCEPTER UNE COURSE
  // =============================================================

  bool acceptOrder(int orderId) {
    if (_currentDriver == null) {
      return false;
    }

    final index = _orders.indexWhere(
      (order) => _toInt(order['id']) == orderId,
    );

    if (index == -1) {
      return false;
    }

    final order = _orders[index];

    // La commande doit toujours être disponible.
    if (order['statut'] != 'en_attente') {
      return false;
    }

    // Une commande déjà attribuée ne peut plus être prise.
    if (order['deliverer_id'] != null) {
      return false;
    }

    final driverId = _toInt(_currentDriver!['id']);
    if (driverId == null) return false;

    final requestedDriverId = _toInt(order['requested_driver_id']);

    // Si le client a choisi un livreur précis,
    // seul celui-ci peut accepter.
    if (requestedDriverId != null &&
        requestedDriverId != driverId) {
      return false;
    }

    // Vérifier qu'il n'a pas déjà une autre course
    // réellement active.
    final anotherActiveOrder = _orders.any(
      (otherOrder) =>
          otherOrder['id'] != orderId &&
          _toInt(otherOrder['deliverer_id']) == driverId &&
          (otherOrder['statut'] == 'traitee' ||
              otherOrder['statut'] == 'en_cours'),
    );

    if (anotherActiveOrder) {
      return false;
    }

    // =========================================================
    // ACCEPTATION
    // =========================================================

    order['deliverer_id'] = driverId;

    // Conforme au contrat API :
    // en_attente → traitee
    order['statut'] = 'traitee';

    // Maintenant seulement le livreur devient occupé.
    _currentDriver!['disponible'] = false;
    _currentDriver!['reserve_client'] = false;
    _currentDriver!['reservation_type'] = null;

    final driverIndex = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (driverIndex != -1) {
      _drivers[driverIndex]['disponible'] = false;
      _drivers[driverIndex]['reserve_client'] = false;
      _drivers[driverIndex]['reservation_type'] = null;
    }

    notifyListeners();

    return true;
  }

  // =============================================================
  // CRÉER UNE COMMANDE CLIENT
  // =============================================================

  Map<String, dynamic>? createClientOrder({
    required String client,
    required String telephoneClient,
    required String type,
    required int driverId,
    required String pickupAdresse,
    required String destinationAdresse,
    required double pickupLat,
    required double pickupLng,
    required double destinationLat,
    required double destinationLng,
    String note = '',
  }) {
    final driverIndex = _drivers.indexWhere(
      (driver) => driver['id'] == driverId,
    );

    if (driverIndex == -1) {
      return null;
    }

    final driver = _drivers[driverIndex];

    // Le livreur doit avoir été réservé.
    if (driver['reserve_client'] != true) {
      return null;
    }

    // Vérifier qu'il n'a pas déjà une commande.
    final alreadyBusy = _orders.any(
      (order) =>
          order['deliverer_id'] == driverId &&
          order['statut'] != 'livree',
    );

    if (alreadyBusy) {
      return null;
    }

    // Calcul distance.
    final distanceKm = _calculateDistance(
      pickupLat,
      pickupLng,
      destinationLat,
      destinationLng,
    );

    // Tarif client avec réduction éventuelle à partir de 4 km.
    final prixEstime = calculerTarifClient(distanceKm);
    final tarifBase = calculerTarifBase(distanceKm);

    // ID temporaire.
    final random = Random();

    final id = 3000 + random.nextInt(7000);

    final order = <String, dynamic>{
      'id': id,

      'client': client,
      'telephone_client': telephoneClient,

      'type': type,

      'pickup_adresse': pickupAdresse,
      'dest_adresse': destinationAdresse,

      'pickup_lat': pickupLat,
      'pickup_lng': pickupLng,

      'dest_lat': destinationLat,
      'dest_lng': destinationLng,

      'distance_km': distanceKm,
      'tarif_base': tarifBase,
      'reduction_client': tarifBase - prixEstime,
      'prix_estime': prixEstime,

      // Le client a demandé ce livreur.
      'requested_driver_id': driverId,

      // MAIS le livreur n'a pas encore accepté.
      'deliverer_id': null,

      // Création = attente.
      'statut': 'en_attente',

      'note': note,
    };

    _orders.add(order);
    _latestClientOrderId = id;

    // Le livreur reste réservé.
    //
    // Il n'est PAS encore occupé.
    driver['disponible'] = true;
    driver['reserve_client'] = true;
    driver['reservation_type'] = type;

    if (_currentDriver?['id'] == driverId) {
      _currentDriver =
          Map<String, dynamic>.from(driver);
    }

    notifyListeners();

    return Map<String, dynamic>.from(order);
  }

  // =============================================================
  // DÉMARRER LA COURSE
  // =============================================================

  bool startOrder(int orderId) {
    final index = _orders.indexWhere(
      (order) => _toInt(order['id']) == orderId,
    );

    if (index == -1) {
      return false;
    }

    final driverId = _toInt(_currentDriver?['id']);
    if (driverId == null) return false;

    if (_toInt(_orders[index]['deliverer_id']) != driverId) {
      return false;
    }

    // Seulement après acceptation.
    if (_orders[index]['statut'] != 'traitee') {
      return false;
    }

    _orders[index]['statut'] = 'en_cours';

    notifyListeners();

    return true;
  }

  // =============================================================
  // TERMINER LA COURSE
  // =============================================================

  bool finishOrder(int orderId) {
    final index = _orders.indexWhere(
      (order) => _toInt(order['id']) == orderId,
    );

    if (index == -1) {
      return false;
    }

    final driverId = _toInt(_currentDriver?['id']);
    if (driverId == null) return false;

    if (_toInt(_orders[index]['deliverer_id']) != driverId) {
      return false;
    }

    if (_orders[index]['statut'] != 'en_cours') {
      return false;
    }

    final order = _orders[index];

    order['statut'] = 'livree';

    final distance =
        (order['distance_km'] as num).toDouble();

    final tarifBase = calculerTarifBase(distance);
    final prixFinal = calculerTarifClient(distance);

    order['tarif_base'] = tarifBase;
    order['reduction_client'] = tarifBase - prixFinal;
    order['prix_final'] = prixFinal;

    _completedOrders.add(
      Map<String, dynamic>.from(order),
    );

    // Le livreur redevient disponible.
    if (_currentDriver != null) {
      _currentDriver!['disponible'] = true;
      _currentDriver!['reserve_client'] = false;
      _currentDriver!['reservation_type'] = null;

      final currentDriverId =
          _currentDriver!['id'];

      final driverIndex = _drivers.indexWhere(
        (driver) => driver['id'] == currentDriverId,
      );

      if (driverIndex != -1) {
        _drivers[driverIndex]['disponible'] = true;
        _drivers[driverIndex]['reserve_client'] = false;
        _drivers[driverIndex]['reservation_type'] = null;
      }
    }

    notifyListeners();

    return true;
  }

  // =============================================================
  // HISTORIQUE
  // =============================================================

  List<Map<String, dynamic>> get completedOrders {
    final driverId = _currentDriver?['id'];

    if (driverId == null) {
      return [];
    }

    return _completedOrders
        .where(
          (order) =>
              order['deliverer_id'] == driverId,
        )
        .map(
          (order) => Map<String, dynamic>.from(order),
        )
        .toList();
  }

  // =============================================================
  // STATISTIQUES
  // =============================================================

  int get completedCount {
    return completedOrders.length;
  }

  int get totalRevenue {
    return completedOrders.fold(
      0,
      (total, order) =>
          total +
          ((order['prix_final'] ?? 0) as num).toInt(),
    );
  }

  double get totalDistance {
    return completedOrders.fold(
      0.0,
      (total, order) =>
          total +
          ((order['distance_km'] ?? 0) as num).toDouble(),
    );
  }

  // =============================================================
  // ADMIN : GESTION DES LIVREURS
  // =============================================================

  List<Map<String, dynamic>> get allDrivers =>
      _drivers.map((driver) => Map<String, dynamic>.from(driver)).toList();

  Map<String, dynamic>? createDriver({
    required String nom,
    required String telephone,
    required String identifiant,
    required String motDePasse,
  }) {
    if (_drivers.any((d) => d['identifiant'] == identifiant)) {
      return null;
    }

    final id = _drivers.isEmpty
        ? 1
        : (_drivers.map((d) => (d['id'] as num).toInt()).reduce(max) + 1);

    final driver = <String, dynamic>{
      'id': id,
      'identifiant': identifiant,
      'mot_de_passe': motDePasse,
      'nom': nom,
      'telephone': telephone,
      'disponible': false,
      'reserve_client': false,
      'reservation_type': null,
      'latitude': 6.3703,
      'longitude': 2.3912,
    };

    _drivers.add(driver);
    notifyListeners();
    return Map<String, dynamic>.from(driver);
  }

  bool updateDriver({
    required int driverId,
    String? nom,
    String? telephone,
    String? identifiant,
    bool? disponible,
  }) {
    final index = _drivers.indexWhere((d) => d['id'] == driverId);
    if (index == -1) return false;

    if (identifiant != null &&
        _drivers.any((d) => d['id'] != driverId && d['identifiant'] == identifiant)) {
      return false;
    }

    final driver = _drivers[index];
    if (nom != null) driver['nom'] = nom;
    if (telephone != null) driver['telephone'] = telephone;
    if (identifiant != null) driver['identifiant'] = identifiant;
    if (disponible != null && driver['reserve_client'] != true) {
      driver['disponible'] = disponible;
    }

    if (_currentDriver?['id'] == driverId) {
      _currentDriver = Map<String, dynamic>.from(driver);
    }

    notifyListeners();
    return true;
  }

  bool deleteDriver(int driverId) {
    final hasOrder = _orders.any((o) =>
        (o['deliverer_id'] == driverId || o['requested_driver_id'] == driverId) &&
        o['statut'] != 'livree');
    if (hasOrder) return false;

    final index = _drivers.indexWhere((d) => d['id'] == driverId);
    if (index == -1) return false;
    _drivers.removeAt(index);
    if (_currentDriver?['id'] == driverId) {
      _currentDriver = null;
    }
    notifyListeners();
    return true;
  }

  // Réinitialise uniquement le scénario de test local.
  void resetDemoState() {
    for (final order in _orders) {
      if (order['statut'] != 'livree') {
        order['deliverer_id'] = null;
        order['statut'] = 'en_attente';
      }
    }
    for (final driver in _drivers) {
      driver['disponible'] = true;
      driver['reserve_client'] = false;
      driver['reservation_type'] = null;
    }
    _currentDriver = _currentDriver == null
        ? null
        : Map<String, dynamic>.from(
            _drivers.firstWhere((d) => d['id'] == _currentDriver!['id'], orElse: () => _currentDriver!),
          );
    notifyListeners();
  }

  // =============================================================
  // CRÉER UNE COMMANDE DE TEST
  // =============================================================

  void createTestOrder() {
    final random = Random();

    final id = 2000 + random.nextInt(7000);

    _orders.add({
      'id': id,

      'client': 'Client TEST',
      'telephone_client': '+22997000000',

      'type': 'livraison',

      'pickup_adresse':
          'Cotonou - Point de départ TEST',

      'dest_adresse':
          'Cotonou - Destination TEST',

      'pickup_lat': 6.3700,
      'pickup_lng': 2.3900,

      'dest_lat': 6.3800,
      'dest_lng': 2.4000,

      'distance_km': 3.0,
      'tarif_base': 1000,
      'reduction_client': 0,
      'prix_estime': 1000,

      'statut': 'en_attente',

      'deliverer_id': null,
      'requested_driver_id': null,

      'note': 'Commande créée pour le test.',
    });

    notifyListeners();
  }

  // =============================================================
  // RECHERCHER UNE COMMANDE
  // =============================================================

  // Convertit de manière sûre les identifiants venant de Map<String, dynamic>.
  // Cela évite les erreurs int? -> int lorsque les données sont issues
  // d'une réponse JSON ou d'un formulaire.
  int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Map<String, dynamic>? getOrderById(
    int orderId,
  ) {
    for (final order in _orders) {
      if (order['id'] == orderId) {
        return Map<String, dynamic>.from(order);
      }
    }

    for (final order in _completedOrders) {
      if (order['id'] == orderId) {
        return Map<String, dynamic>.from(order);
      }
    }

    return null;
  }

  // =============================================================
  // FORCER ACTUALISATION
  // =============================================================

  void refresh() {
    notifyListeners();
  }

  // =============================================================
  // CALCUL DE DISTANCE GPS
  // =============================================================

  double _calculateDistance(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadius = 6371.0;

    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);

    final c =
        2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }
}