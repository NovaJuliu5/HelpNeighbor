import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_avis.dart';

class DepotAvis {
  final ClientApi _api;
  DepotAvis(this._api);

  Future<Either<Echec, List<EntiteAvis>>> getAvisPourCible(
      String cibleId, {
        String? serviceId,
      }) async {
    try {
      final response = await _api.get('/avis', query: {
        'cible_id': cibleId,
        if (serviceId != null) 'service_id': serviceId,
      });
      final List list = response.data;
      return Right(list.map((e) => EntiteAvis.fromJson(e)).toList());
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  // Modification : listerAvis accepte désormais serviceId optionnel
  Future<Either<Echec, List<EntiteAvis>>> listerAvis({
    String? cibleId,
    String? cibleType,
    String? serviceId,
  }) async {
    try {
      final query = <String, dynamic>{};
      if (cibleId != null) query['cible_id'] = cibleId;
      if (cibleType != null) query['cible_type'] = cibleType;
      if (serviceId != null) query['service_id'] = serviceId;
      final response = await _api.get('/avis', query: query);
      final list = (response.data as List).map((json) => EntiteAvis.fromJson(json)).toList();
      return Right(list);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, void>> creerAvis(Map<String, dynamic> data) async {
    try {
      await _api.post('/avis', data: data);
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, void>> ajouterAvis({
    required String cibleId,
    required String cibleType,
    required double noteGlobale,
    String? commentaire,
    String? serviceId,
    String? demandeId,
  }) async {
    try {
      await _api.post('/avis', data: {
        'cible_id': cibleId,
        'cible_type': cibleType,
        'service_id': serviceId,
        'demande_id': demandeId,
        'commentaire': commentaire,
        'note_globale': noteGlobale,
        'note_qualite': noteGlobale,
        'note_ponctualite': noteGlobale,
        'note_communication': noteGlobale,
        'note_prix': noteGlobale,
      });
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, EntiteAvis?>> getAvisCurrent(
      String cibleId, {
        String? serviceId,
      }) async {
    try {
      final response = await _api.get('/avis/current', query: {
        'cible_id': cibleId,
        if (serviceId != null) 'service_id': serviceId,
      });
      return Right(EntiteAvis.fromJson(response.data));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        return const Right(null);
      }
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, EntiteAvis>> getAvisById(String avisId) async {
    try {
      final response = await _api.get('/avis/$avisId');
      return Right(EntiteAvis.fromJson(response.data));
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }

  Future<Either<Echec, void>> modifierAvis(
      String avisId,
      Map<String, dynamic> data,
      ) async {
    try {
      await _api.put('/avis/$avisId', data: data);
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}