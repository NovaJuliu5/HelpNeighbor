import 'package:dartz/dartz.dart';
import 'package:help_neighbor/coeur/erreurs/echec.dart';
import 'package:help_neighbor/donnees/depots/depot_avis.dart';

class CreerAvisUseCase {
  final DepotAvis depot;
  CreerAvisUseCase(this.depot);

  Future<Either<Echec, void>> executer(Map<String, dynamic> data) {
    return depot.creerAvis(data);
  }
}