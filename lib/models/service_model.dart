class ServiceModel {
  final int id;
  final String nom;

  ServiceModel({required this.id, required this.nom});

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    return ServiceModel(id: json['id'] ?? 0, nom: json['nom'] ?? '');
  }
}
