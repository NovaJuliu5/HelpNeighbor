class EntiteDemande {
  final String id;
  final String titre;
  final String description;
  final String statut;
  final DateTime createdAt;
  final String utilisateurNom;
  final String utilisateurId;
  final String? photoUrl;
  final String? adresse;        // NOUVEAU

  EntiteDemande({
    required this.id,
    required this.titre,
    required this.description,
    required this.statut,
    required this.createdAt,
    required this.utilisateurNom,
    required this.utilisateurId,
    this.photoUrl,
    this.adresse,               // NOUVEAU
  });

  factory EntiteDemande.fromJson(Map<String, dynamic> json) {
    return EntiteDemande(
      id: json['id'] ?? '',
      titre: json['titre'] ?? 'Nouvelle demande',
      description: json['description'] ?? '',
      statut: json['statut'] ?? 'ouverte',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      utilisateurNom: json['utilisateur_nom'] ??
          '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      utilisateurId: json['utilisateur_id'] ?? '',
      photoUrl: json['photo_url'],
      adresse: json['adresse'],   // NOUVEAU
    );
  }
}