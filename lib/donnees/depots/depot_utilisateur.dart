import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_utilisateur.dart';

class DepotUtilisateur {
  final ClientApi _api;
  DepotUtilisateur(this._api);

  /// Vérifie si une chaîne est un UUID valide.
  bool _isValidUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }

  Future<Either<Echec, EntiteUtilisateur>> obtenirProfil(String id) async {
    // Validation locale de l'UUID
    if (!_isValidUuid(id)) {
      // Utilisation d'une sous-classe concrète d'Echec
      return Left(EchecServeur('ID utilisateur invalide : $id (format UUID requis)'));
    }
    try {
      final response = await _api.get('/utilisateurs/$id');
      return Right(EntiteUtilisateur.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, EntiteUtilisateur>> mettreAJourProfil(Map<String, dynamic> donnees) async {
    try {
      final response = await _api.put('/utilisateurs/profil', data: donnees);
      return Right(EntiteUtilisateur.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}