class EntiteService {
  final String id;
  final String titre;
  final String description;
  final double prix;
  final String categorie;
  final String utilisateurId;
  final String utilisateurNom;
  final double distanceKm;      // gardé pour compatibilité, mais vous pouvez l'ignorer
  final double noteMoyenne;
  final int nbAvis;
  final String? photoUrl;
  final String? adresse;        // NOUVEAU

  EntiteService({
    required this.id,
    required this.titre,
    required this.description,
    required this.prix,
    required this.categorie,
    required this.utilisateurId,
    required this.utilisateurNom,
    required this.distanceKm,
    required this.noteMoyenne,
    required this.nbAvis,
    this.photoUrl,
    this.adresse,               // NOUVEAU
  });

  factory EntiteService.fromJson(Map<String, dynamic> json) {
    return EntiteService(
      id: json['id'] ?? '',
      titre: json['titre'] ?? '',
      description: json['description'] ?? '',
      prix: (json['prix'] is num ? (json['prix'] as num).toDouble() : 0.0),
      categorie: json['categorie_nom'] ?? 'Sans catégorie',
      utilisateurId: json['utilisateur_id'] ?? '',
      utilisateurNom: '${json['prenom'] ?? ''} ${json['nom'] ?? ''}'.trim(),
      distanceKm: (json['distance_km'] is num ? (json['distance_km'] as num).toDouble() : 0.0),
      noteMoyenne: (json['note_moyenne'] is num ? (json['note_moyenne'] as num).toDouble() : 0.0),
      nbAvis: (json['nb_avis'] is int ? json['nb_avis'] : int.tryParse(json['nb_avis']?.toString() ?? '0') ?? 0),
      photoUrl: json['photo_url'],
      adresse: json['adresse'],   // NOUVEAU
    );
  }
}