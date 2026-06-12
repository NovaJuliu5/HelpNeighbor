import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import '../../coeur/erreurs/echec.dart';

class DepotDemande {
  final ClientApi _api;
  DepotDemande(this._api);

  // Récupérer les demandes à proximité
  Future<Either<Echec, List<EntiteDemande>>> obtenirDemandesProches(double lat, double lon, int rayonKm) async {
    try {
      print('GET /demandes/proches avec params lat=$lat, lon=$lon, rayon=$rayonKm');
      final response = await _api.get('/demandes/proches', query: {'lat': lat, 'lon': lon, 'rayon': rayonKm});
      final List list = response.data;
      return Right(list.map((e) => EntiteDemande.fromJson(e)).toList());
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Créer une nouvelle demande
  Future<Either<Echec, EntiteDemande>> creerDemande(Map<String, dynamic> data) async {
    try {
      print('POST /demandes avec data: $data');
      final response = await _api.post('/demandes', data: data);
      print('Réponse création: ${response.data}');
      return Right(EntiteDemande.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Mettre à jour une demande (modification)
  Future<Either<Echec, EntiteDemande>> mettreAJourDemande(String id, Map<String, dynamic> data) async {
    try {
      print('PUT /demandes/$id avec data: $data');
      final response = await _api.put('/demandes/$id', data: data);
      print('Réponse mise à jour: ${response.data}');
      return Right(EntiteDemande.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Supprimer une demande
  Future<Either<Echec, void>> supprimerDemande(String id) async {
    try {
      print('DELETE /demandes/$id');
      await _api.delete('/demandes/$id');
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Récupérer une demande par son ID
  Future<Either<Echec, EntiteDemande>> obtenirDemandeParId(String id) async {
    try {
      print('GET /demandes/$id');
      final response = await _api.get('/demandes/$id');
      print('Données reçues : ${response.data}');
      return Right(EntiteDemande.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
  Future<Either<Echec, void>> changerStatutDemande(String id, String statut) async {
    try {
      await _api.put('/demandes/$id/statut', data: {'statut': statut});
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}
