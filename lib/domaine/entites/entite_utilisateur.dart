class EntiteUtilisateur {
  final String id;
  final String email;
  final String? telephone;
  final String? nom;
  final String? prenom;
  final String? photoUrl;
  final double noteMoyenne;
  final String? bio;
  final int? nbServices;
  final int? nbDemandes;
  final String? adresse;
  final String? ville;
  final String? codePostal;
  final String? pays;
  final String? role; // Ajout

  EntiteUtilisateur({
    required this.id,
    required this.email,
    this.telephone,
    this.nom,
    this.prenom,
    this.photoUrl,
    required this.noteMoyenne,
    this.bio,
    this.nbServices,
    this.nbDemandes,
    this.adresse,
    this.ville,
    this.codePostal,
    this.pays,
    this.role,
  });

  factory EntiteUtilisateur.fromJson(Map<String, dynamic> json) {
    return EntiteUtilisateur(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      telephone: json['telephone'],
      nom: json['nom'],
      prenom: json['prenom'],
      photoUrl: json['photo_url'],
      noteMoyenne: (json['note_moyenne'] ?? 0).toDouble(),
      bio: json['bio'],
      nbServices: json['nb_services'],
      nbDemandes: json['nb_demandes'],
      adresse: json['adresse'],
      ville: json['ville'],
      codePostal: json['code_postal'],
      pays: json['pays'],
      role: json['role'],
    );
  }
}