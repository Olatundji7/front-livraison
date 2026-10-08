class OrderModel {
  final int id;
  final String statut;
  final double? distanceKm;
  final double? distanceTravelledKm;
  final int? prixEstime;
  final int? prixFinal;
  final String? pickupAdresse;
  final String? destAdresse;
  final double? pickupLat;
  final double? pickupLng;
  final double? destinationLat;
  final double? destinationLng;
  final Map<String, dynamic>? deliverer;

  OrderModel({
    required this.id,
    required this.statut,
    this.distanceKm,
    this.distanceTravelledKm,
    this.prixEstime,
    this.prixFinal,
    this.pickupAdresse,
    this.destAdresse,
    this.pickupLat,
    this.pickupLng,
    this.destinationLat,
    this.destinationLng,
    this.deliverer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    int? asInt(Object? v) => v is int ? v : v is num ? v.toInt() : v == null ? null : int.tryParse(v.toString());
    double? asDouble(Object? v) => v is num ? v.toDouble() : v == null ? null : double.tryParse(v.toString());
    return OrderModel(
      id: asInt(json['id']) ?? 0,
      statut: (json['status'] ?? json['statut'] ?? 'en_attente').toString(),
      distanceKm: asDouble(json['distance_km'] ?? json['distanceKm']),
      distanceTravelledKm: asDouble(json['distance_travelled_km'] ?? json['distance_km_reel']),
      prixEstime: asInt(json['prix_estime'] ?? json['total']),
      prixFinal: asInt(json['prix_final']),
      pickupAdresse: json['pickup_address']?.toString() ?? json['pickup_adresse']?.toString(),
      destAdresse: json['destination_address']?.toString() ?? json['dest_adresse']?.toString(),
      pickupLat: asDouble(json['pickup_latitude'] ?? json['pickup_lat']),
      pickupLng: asDouble(json['pickup_longitude'] ?? json['pickup_lng']),
      destinationLat: asDouble(json['destination_latitude'] ?? json['dest_lat']),
      destinationLng: asDouble(json['destination_longitude'] ?? json['dest_lng']),
      deliverer: json['driver'] is Map
          ? Map<String, dynamic>.from(json['driver'] as Map)
          : json['deliverer'] is Map
              ? Map<String, dynamic>.from(json['deliverer'] as Map)
              : null,
    );
  }
}
