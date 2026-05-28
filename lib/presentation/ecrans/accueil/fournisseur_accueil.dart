import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:help_neighbor/app/dependances.dart';
import 'package:help_neighbor/domaine/cas_utilisation/service/obtenir_services_proches_usecase.dart';
import 'package:help_neighbor/domaine/cas_utilisation/demande/obtenir_demandes_usecase.dart';
import 'package:help_neighbor/domaine/entites/entite_service.dart';
import 'package:help_neighbor/domaine/entites/entite_demande.dart';
import 'package:help_neighbor/presentation/fournisseurs/fournisseur_localisation.dart';

final servicesProchesProvider = FutureProvider<List<EntiteService>>((ref) async {
  print("🔍 servicesProchesProvider appelé");
  final position = await ref.watch(localisationProvider.future);
  print("📍 Position: ${position.latitude}, ${position.longitude}");
  final useCase = ObtenirServicesProchesUseCase(getIt());
  final result = await useCase.executer(position.latitude, position.longitude, 10);
  print("📦 Résultat: $result");
  return result.fold(
        (echec) {
      print("❌ Erreur: ${echec.message}");
      throw Exception(echec.message);
    },
        (services) {
      print("✅ ${services.length} services trouvés");
      return services;
    },
  );
});

final demandesProchesProvider = FutureProvider<List<EntiteDemande>>((ref) async {
  final position = await ref.watch(localisationProvider.future);
  final useCase = ObtenirDemandesUseCase(getIt());
  final result = await useCase.executer(position.latitude, position.longitude, 10);
  return result.fold(
        (echec) => throw Exception(echec.message),
        (demandes) => demandes,
  );
});