import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/domaine/cas_utilisation/service/obtenir_services_proches_usecase.dart';
import 'package:help_neighbor/domaine/cas_utilisation/demande/obtenir_demandes_usecase.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';

final servicesProchesProvider = FutureProvider<List<EntiteService>>((ref) async {
  final useCase = ObtenirServicesProchesUseCase(getIt());
  final result = await useCase.executer(0.0, 0.0, 10); // valeurs factices
  return result.fold(
        (echec) => throw Exception(echec.message),
        (services) => services,
  );
});

final demandesProchesProvider = FutureProvider<List<EntiteDemande>>((ref) async {
  final useCase = ObtenirDemandesUseCase(getIt());
  final result = await useCase.executer(0.0, 0.0, 10); // valeurs factices
  return result.fold(
        (echec) => throw Exception(echec.message),
        (demandes) => demandes,
  );
});