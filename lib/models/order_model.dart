class OrderModel {
  final int id;
  final String statut;
  final double? distanceKm;
  final double? distanceTravelledKm;
  final int? prixEstime;
  final int? prixFinal;
  final int? deliveryFee;
  final int? total;
  final int? serviceFee;
  final String? paymentStatus;
  final String? pickupAdresse;
  final double? pickupLat;
  final double? pickupLng;
  final String? destAdresse;
  final double? destLat;
  final double? destLng;
  final Map<String, dynamic>? deliverer;

  const OrderModel({
    required this.id,
    required this.statut,
    this.distanceKm,
    this.distanceTravelledKm,
    this.prixEstime,
    this.prixFinal,
    this.deliveryFee,
    this.total,
    this.serviceFee,
    this.paymentStatus,
    this.pickupAdresse,
    this.pickupLat,
    this.pickupLng,
    this.destAdresse,
    this.destLat,
    this.destLng,
    this.deliverer,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    int? toInt(Object? v) => v is num ? v.toInt() : int.tryParse(v?.toString() ?? '');
    double? toDouble(Object? v) => v is num ? v.toDouble() : double.tryParse(v?.toString() ?? '');

    return OrderModel(
      id: toInt(json['id']) ?? 0,
      statut: (json['status'] ?? json['statut'] ?? 'en_attente').toString(),
      distanceKm: toDouble(json['distance_km']),
      distanceTravelledKm: toDouble(json['distance_travelled_km']),
      prixEstime: toInt(json['prix_estime'] ?? json['total']),
      prixFinal: toInt(json['prix_final']),
      deliveryFee: toInt(json['delivery_fee'] ?? json['net_course_amount']),
      total: toInt(json['total']),
      serviceFee: toInt(json['service_fee']),
      paymentStatus: json['payment_status']?.toString(),
      pickupAdresse: json['pickup_address']?.toString() ?? json['pickup_adresse']?.toString(),
      pickupLat: toDouble(json['pickup_latitude'] ?? json['pickup_lat']),
      pickupLng: toDouble(json['pickup_longitude'] ?? json['pickup_lng']),
      destAdresse: json['destination_address']?.toString() ?? json['dest_adresse']?.toString(),
      destLat: toDouble(json['destination_latitude'] ?? json['dest_lat']),
      destLng: toDouble(json['destination_longitude'] ?? json['dest_lng']),
      deliverer: json['driver'] is Map
          ? Map<String, dynamic>.from(json['driver'] as Map)
          : (json['deliverer'] is Map ? Map<String, dynamic>.from(json['deliverer'] as Map) : null),
    );
  }
}
