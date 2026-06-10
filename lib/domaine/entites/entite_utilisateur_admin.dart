class UtilisateurAdmin {
  final String id;
  final String email;
  final String? telephone;
  final String? nom;
  final String? prenom;
  final String role;
  final int nbServices;
  final int nbDemandes;
  final DateTime dateCreation;

  UtilisateurAdmin({
    required this.id,
    required this.email,
    this.telephone,
    this.nom,
    this.prenom,
    required this.role,
    required this.nbServices,
    required this.nbDemandes,
    required this.dateCreation,
  });

  factory UtilisateurAdmin.fromJson(Map<String, dynamic> json) {
    return UtilisateurAdmin(
      id: json['id'],
      email: json['email'],
      telephone: json['telephone'],
      nom: json['nom'],
      prenom: json['prenom'],
      role: json['role'] ?? 'user',
      nbServices: _toInt(json['nb_services']),
      nbDemandes: _toInt(json['nb_demandes']),
      dateCreation: DateTime.parse(json['created_at']),
    );
  }

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}