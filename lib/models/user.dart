class UserModel {
  final int id;
  final String nom;
  final String role;
  final String? telephone;
  final String? email;
  final Map<String, dynamic>? deliverer;

  UserModel({
    required this.id,
    required this.nom,
    required this.role,
    this.telephone,
    this.email,
    this.deliverer,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: _toInt(json['id']) ?? 0,
      nom: (json['name'] ?? json['nom'] ?? '').toString(),
      role: (json['role'] ?? 'client').toString(),
      telephone: (json['phone'] ?? json['telephone'])?.toString(),
      email: json['email']?.toString(),
      deliverer: json['deliverer'] is Map
          ? Map<String, dynamic>.from(json['deliverer'] as Map)
          : null,
    );
  }

  static int? _toInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return value == null ? null : int.tryParse(value.toString());
  }
}
