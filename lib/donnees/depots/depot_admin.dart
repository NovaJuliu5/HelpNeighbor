import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_utilisateur_admin.dart';

class DepotAdmin {
  final ClientApi _api;
  DepotAdmin(this._api);

  // Liste des utilisateurs
  Future<Either<Echec, List<UtilisateurAdmin>>> listerUtilisateurs() async {
    try {
      final response = await _api.get('/admin/utilisateurs');
      final list = (response.data as List).map((json) => UtilisateurAdmin.fromJson(json)).toList();
      return Right(list);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Changer le rôle d'un utilisateur
  Future<Either<Echec, void>> changerRole(String userId, String role) async {
    try {
      await _api.put('/admin/utilisateurs/$userId/role', data: {'role': role});
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Supprimer un utilisateur (soft delete)
  Future<Either<Echec, void>> supprimerUtilisateur(String userId) async {
    try {
      await _api.delete('/admin/utilisateurs/$userId');
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Lister les signalements
  Future<Either<Echec, List<dynamic>>> listerSignalements() async {
    try {
      final response = await _api.get('/admin/signalements');
      return Right(response.data);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Supprimer un contenu (service, demande ou avis)
  Future<Either<Echec, void>> supprimerContenu(String type, String id) async {
    try {
      await _api.delete('/admin/contenu/$type/$id');
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}