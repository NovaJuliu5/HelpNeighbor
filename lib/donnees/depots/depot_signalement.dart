import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/coeur/erreurs/gestionnaire_erreurs.dart';
import 'package:help_neighbor/donnees/sources_donnees/distantes/client_api.dart';

class DepotSignalement {
  final ClientApi _api;
  DepotSignalement(this._api);

  Future<Either<Echec, String>> signaler({
    required String cibleType,
    required String cibleId,
    required String motif,
    String? description,
  }) async {
    try {
      final response = await _api.post('/signalements', data: {
        'cible_type': cibleType,
        'cible_id': cibleId,
        'motif': motif,
        'description': description,
      });
      return Right(response.data['message'] as String);
    } catch (e) {
      return Left(GestionnaireErreurs.traiterErreur(e));
    }
  }
}