import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_offre.dart';

class DepotOffre {
  final ClientApi _api;
  DepotOffre(this._api);

  Future<Either<Echec, EntiteOffre>> creerOffre(Map<String, dynamic> data) async {
    try {
      final response = await _api.post('/offres', data: data);
      return Right(EntiteOffre.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, List<EntiteOffre>>> getOffresPourDemande(String demandeId) async {
    try {
      final response = await _api.get('/offres/demande/$demandeId');
      final List list = response.data;
      return Right(list.map((e) => EntiteOffre.fromJson(e)).toList());
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, void>> repondreOffre(String offreId, String statut) async {
    try {
      await _api.put('/offres/$offreId', data: {'statut': statut});
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}