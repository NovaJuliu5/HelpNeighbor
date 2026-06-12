class EntiteDemande {
  final String id;
  final String titre;
  final String description;
  final double prix;
  final String statut;
  final DateTime createdAt;
  final String utilisateurId;
  final String utilisateurNom;
  final String? photoUrl;
  final String? adresse;

  EntiteDemande({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.statut,
    required this.createdAt,
    required this.utilisateurId,
    required this.utilisateurNom,
    this.photoUrl,
    this.adresse,
  });

  factory EntiteDemande.fromJson(Map<String, dynamic> json) {
    return EntiteDemande(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      prix: _toDouble(json['prix']),
      statut: json['statut'] ?? 'ouverte',
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      utilisateurId: json['utilisateur_id'] ?? '',
      utilisateurNom: json['nom'] ?? 'Inconnu',
      photoUrl: json['photo_url'],
      adresse: json['adresse'],
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}