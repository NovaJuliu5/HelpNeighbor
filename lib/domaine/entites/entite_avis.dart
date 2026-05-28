class EntiteAvis {
  final String id;
  final String auteurId;
  final String auteurNom;
  final String cibleId;
  final String cibleType;
  final String? serviceId;
  final String? demandeId;
  final String? commentaire;
  final double noteGlobale;
  final double? noteQualite;
  final double? notePonctualite;
  final double? noteCommunication;
  final double? notePrix;
  final DateTime createdAt;

  EntiteAvis({
    required this.id,
    required this.auteurId,
    required this.auteurNom,
    required this.cibleId,
    required this.cibleType,
    this.serviceId,
    this.demandeId,
    this.commentaire,
    required this.noteGlobale,
    this.noteQualite,
    this.notePonctualite,
    this.noteCommunication,
    this.notePrix,
    required this.createdAt,
  });

  factory EntiteAvis.fromJson(Map<String, dynamic> json) {
    return EntiteAvis(
      id: json['id'] ?? '',
      auteurId: json['auteur_id'] ?? '',
      auteurNom: '${json['auteur_prenom'] ?? ''} ${json['auteur_nom'] ?? ''}'.trim(),
      cibleId: json['cible_id'] ?? '',
      cibleType: json['cible_type'] ?? '',
      serviceId: json['service_id'],
      demandeId: json['demande_id'],
      commentaire: json['commentaire'],
      noteGlobale: (json['note_globale'] ?? 0).toDouble(),
      noteQualite: json['note_qualite']?.toDouble(),
      notePonctualite: json['note_ponctualite']?.toDouble(),
      noteCommunication: json['note_communication']?.toDouble(),
      notePrix: json['note_prix']?.toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }
}