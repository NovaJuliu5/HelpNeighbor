import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';
import 'package:help_neighbor/domaine/entites/entite_avis.dart';
import 'package:dio/dio.dart';

class DepotAvis {
  final ClientApi _api;
  DepotAvis(this._api);

  Future<Either<Echec, List<EntiteAvis>>> getAvisPourCible(String cibleId, {String? serviceId}) async {
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

  Future<Either<Echec, void>> creerAvis(Map<String, dynamic> data) async {
    try {
      await _api.post('/avis', data: data);
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
  Future<Either<Echec, EntiteAvis?>> getAvisCurrent(String cibleId, {String? serviceId}) async {
    try {
      final response = await _api.get('/avis/current', query: {
        'cible_id': cibleId,
        if (serviceId != null) 'service_id': serviceId,
      });
      return Right(EntiteAvis.fromJson(response.data));
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) return const Right(null);
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

  Future<Either<Echec, void>> modifierAvis(String avisId, Map<String, dynamic> data) async {
    try {
      await _api.put('/avis/$avisId', data: data);
      return const Right(null);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}